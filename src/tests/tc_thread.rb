require 'test/unit'
require 'osx/cocoa'
require 'thread'
system 'make' || raise(RuntimeError, "'make' failed")
require 'objc_test.bundle'

# Helper class to explicitly yield control between threads
class Barrier
  def initialize
    @signalled = nil
    @mutex = Mutex.new
    @cond = ConditionVariable.new
  end
  
  def signal(key)
    @mutex.synchronize do
      @signalled = key
      @cond.broadcast
    end
  end
  
  # Wait until the barrier value reaches num,
  # then increase it by one
  def wait(key)
    @mutex.synchronize do
      while @signalled != key
        @cond.wait(@mutex)
      end
    end
  end
end
  
class TestThreadNativeMethod < OSX::NSObject
  def initWithTC(tc)
    init
    @tc = tc
    return self
  end

  def threaded
    @tc.assert_equal(@tc.mainThread, OSX::NSThread.currentThread)
    if defined? OSX::CFRunLoopGetMain then
      @tc.assert_equal(OSX::CFRunLoopGetCurrent(), OSX::CFRunLoopGetMain())
    end
    42
  end
  objc_method :threaded, ['id']
end

class TC_Thread < Test::Unit::TestCase
  attr_reader :mainThread

  def setup
    @mainThread = OSX::NSThread.currentThread
    @helper = OSX::RBThreadTest.alloc.init
  end

  def threaded
    assert_equal(@mainThread, OSX::NSThread.currentThread)
    if defined? OSX::CFRunLoopGetMain then
      assert_equal(OSX::CFRunLoopGetCurrent(), OSX::CFRunLoopGetMain())
    end
    42
  end

  def test_threaded_callback
    OSX::TestThreadedCallback.callbackOnThreadRubyObject(self)
  end

  def test_threaded_closure
    o = TestThreadNativeMethod.alloc.initWithTC(self)
    OSX::TestThreadedCallback.callbackOnThreadRubyObject(o)
  end
  
  def assert_threads_supported
    assert OSX::RBRuntime.isRubyThreadingSupported?, "no runtime support for Ruby threads" unless ENV['RUBYCOCOA_THREAD_HOOK_DISABLE']
  end
  
  # Run this test with the RUBYCOCOA_THREAD_HOOK_DISABLE set to see what goes 
  # wrong:
  #
  #   Exception handlers were not properly removed. Some code has jumped or 
  #   returned out of an NS_DURING...NS_HANDLER region without using the 
  #   NS_VOIDRETURN or NS_VALUERETURN macros
  #
  # Alternatively, run with /usr/bin/ruby and see other error messages. For 
  # example:
  #
  #   WARNING: multiple libruby.dylib found: '/usr/lib/libruby.1.dylib' and 
  #   '/sw/ruby-thread-hooks/lib/libruby.dylib'
  #   RBCocoaInstallRubyThreadSchedulerHooks: warning: 
  #   rb_set_cocoa_thread_hooks is linked from a different library 
  #   (/sw/ruby-thread-hooks/lib/libruby.dylib) than ruby_init 
  #   (/usr/lib/libruby.1.dylib)
  #
  def test_autorelease
    assert_threads_supported
  
    barrier = Barrier.new
  
    t1 = Thread.new do
      # Execution starts here
      barrier.wait 0
      @helper.callWithAutoreleasePool proc {
        OSX::NSString.stringWithString "x"

        # Now pass control to other thread
        barrier.signal 10
        barrier.wait 20
        
        OSX::NSString.stringWithString "y"
      }
      barrier.signal 30
    end
    
    t2 = Thread.new do
      barrier.wait 10
      @helper.callWithAutoreleasePool proc {
        OSX::NSString.stringWithString "z"
        barrier.signal 20
        barrier.wait 30
      }
    end
    
    barrier.signal 0
    
    t1.join
    t2.join
  end

  # This test creates two separate an objective c exception handler in one 
  # thread, then switches to another thread and sets up an exception handler 
  # there. We then switch back to the first thread to throw an exception, and 
  # finally to the second thread to throw an exception.
  def test_exceptions
    barrier = Barrier.new
  
    t1 = Thread.new do
      # Execution starts here
      barrier.wait 0
      exception = @helper.callWithExceptionTryCatch proc {
      
        barrier.signal 10
        barrier.wait 20
            
        OSX::NSException.exceptionWithName_reason_userInfo_("name1","reason1",nil).raise
      }
      
      assert_equal "name1", exception.name.to_s

      barrier.signal 30
    end
    
    t2 = Thread.new do
      barrier.wait 10
      $RUBYCOCOA_SUPPRESS_EXCEPTION_LOGGING = true
      exception = @helper.callWithExceptionTryCatch proc {
      
        barrier.signal 20
        barrier.wait 30
 
        OSX::NSException.exceptionWithName_reason_userInfo_("name2","reason2",nil).raise
      }
      $RUBYCOCOA_SUPPRESS_EXCEPTION_LOGGING = false 
      
      assert_equal "name2", exception.name.to_s
    end
    
    barrier.signal 0
    
    t1.join
    t2.join
  end
end
