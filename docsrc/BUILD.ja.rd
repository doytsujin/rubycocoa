# -*-rd-*-
= RubyCocoa�򥽡������鹽�ۡ����󥹥ȡ��뤹��

����ʸ��Ǥ�RubyCocoa 0.4�򥽡������鹽�ۡ����󥹥ȡ��뤹����ˡ�ˤĤ���
�������ޤ����Х��ʥ����դ򥤥󥹥ȡ��뤷�ƻȤ����ˤϤȤ����ɤ�ɬ�פϤ���ޤ���

���ۡ����󥹥ȡ����Ȥϡ�Terminal���ץꥱ�������ʤɤ��饷���륳�ޥ��
�����Ϥ��ƹԤ��ޤ��������륳�ޥ��������ˤ�bash�����ꤷ�Ƶ��Ҥ��Ƥ��ޤ���
����¾�Υ�����(�㤨��tcsh)��ȤäƤ����硢Ŭ�����ɤ��Ѥ��Ƥ���������


== ���ۡ����󥹥ȡ���μ��

���ۡ����󥹥ȡ���ϡ������褽�ʲ��Τ褦�ʼ��ǹԤ��ޤ���

  * ((<Ruby�ι��ۡ����󥹥ȡ���>))
  * ((<RubyCocoa�ι���>))
  * ((<RubyCocoa��ñ�Υƥ���>))
  * ((<RubyCocoa�Υ��󥹥ȡ���>))

���餫����ɤ�����RubyCocoa�Υ�������Ÿ�����Ƥ����Ƥ���������

  $ cd {�ɤ���}
  $ tar zxf rubycocoa-0.4.0.tar.gz

((*����*)) StuffIt��Ȥ��ȥե�����̾��Ĺ���������RubyCocoa��������
���󥹥ȡ��뤵��ʤ��Τ�tar���ޥ�ɤ�ȤäƤ���������


== Ruby�ι��ۡ����󥹥ȡ���

RubyCocoa���ۤ��뤿��ˤϡ������libruby��Ruby���տ魯��C�����
�إå����ե����뤬ɬ�פȤʤ�ޤ��������Ǥϼ��˼���������ˡ�
RubyCocoa�Υ١����Ȥʤ�Ruby�ι��ۼ����������ޤ���

  * ���������饤�󥹥ȡ��뤷��Ruby 1.8
  * Mac OS X 10.2��°��Ruby 1.6.7

RubyCocoa 0.4�Х��ʥ�ѥå������ϡ���Ԥ���ˡ�Ǻ��줿��ΤǤ���
((<Fink|URL:http://fink.sf.net/>))�ʤɤΥѥå�������Ȥä�Ruby��
���󥹥ȡ��뤷�Ƥ�����ʤɤϡ�����˹�碌���ɤ��Ѥ��Ƥ���������


=== ���������饤�󥹥ȡ��뤷��Ruby 1.8

Ruby 1.8�Υ������ǥ��쥯�ȥ�˰�ư���ơ��ʲ��Τ褦�˹��ۡ����󥹥ȡ���
���ޤ������ץ�����ɬ�פ˱������ѹ����Ƥ���������
((- CFLAGS��'-fno-common'���ץ�������ꤷ�ʤ��ȡ�RubyCocoa.framework
����󥯤Ǥ��ʤ��褦�Ǥ� -))

  $ CFLAGS='-g -O2 -fno-common' ./configure
  $ make
  $ make test
  $ sudo make install
  $ sudo ranlib /usr/local/lib/libruby-static.a  # 




=== Mac OS X 10.2��°��Ruby 1.6.7

==== ���󥹥ȡ��뤵��Ƥ���Mac OS X�ѥå������γ�ǧ

Mac OS X 10.2�򥤥󥹥ȡ��뤷�����Υ��ץ�������꼡��Ǥϡ�ɬ�פ�
�ѥå�����(BSD.pkg��BSDSDK.pkg)�����󥹥ȡ��뤵��Ƥ��ʤ���ǽ��������ޤ���
�ޤ���Ruby�����󥹥ȡ��뤵��Ƥ��뤫��ǧ���ơ�ɬ�פǤ���Х��󥹥ȡ���
���Ƥ���������

  $ ls -dF /Library/Receipts/BSD*.pkg   # ��ǧ
  /Library/Receipts/BSD.pkg/   /Library/Receipts/BSDSDK.pkg/

Mac OS X 10.2�ˤ�Ruby���ޤޤ�Ƥ��ޤ������ɤ������櫓��libruby
���ޤޤ�Ƥ��ޤ��󡣤������äơ�RubyCocoa���ۤ��뤿��ˤϡ�
Ruby 1.6.7�Υ���������libruby����ɬ�פ�����ޤ���

==== Ruby 1.6.7�Υ������˥ѥå��򤢤Ƥ�

�ޤ��ǽ��Ruby 1.6.7��tarball��Ÿ�����ơ�RubyCocoa����°��
Ruby 1.6.7�ѥѥå��򤢤Ƥޤ���

  $ cd {�ɤ���}
  $ tar zxf ruby-1.6.7.tar.gz
  $ cd ruby-1.6.7
  $ patch -p1 < {RubyCocoa������}/ruby-1.6.7-osx10.2.patch

==== libruby�ι��ۡ����󥹥ȡ���

Mac OS X��°Ruby�δĶ��˹�碌��Ruby 1.6.7���ۤ��ޤ���
((- CFLAGS��'-fno-common'���ץ�������ꤷ�ʤ��ȡ�RubyCocoa.framework
����󥯤Ǥ��ʤ��褦�Ǥ� -))

  $ rbhost=`ruby -r rbconfig -e "print Config::CONFIG['host']"`
  $ CFLAGS='-g -O2 -fno-common' ./configure --prefix=/usr --host=$rbhost
  $ make
  $ make test

libruby.a�Τߤ򥤥󥹥ȡ��뤷�ޤ���

  $ ranlib libruby.a
  $ rubyarchdir=`ruby -r rbconfig -e 'print Config::CONFIG["archdir"]'`
  $ sudo install -m 0644 libruby.a $rubyarchdir


== RubyCocoa�ι���

���Τ褦�����Ϥ���RubyCocoa���ۤ��ޤ���

  $ ruby install.rb --help   # ���ץ����γ�ǧ
  $ ruby install.rb config
  $ ruby install.rb setup

((% ruby install.rb config %))�ˤϤ����Ĥ�RubyCocoa�ѤΥ��ץ���󤬤���ޤ���
ɬ�פʤ�config�ե������ΤȤ��˥��ץ�������ꤷ�Ƥ���������

((*����*)) config �ΤȤ��� Segmentation fault ���顼��ȯ��������ϡ�
��((<RubyCocoa 0.4.0 �� Ruby 1.6.8 �Ǻ��Ȥ���������>))�פ��ǧ���Ƥ���������

== RubyCocoa��ñ�Υƥ���

  $ cd {������}/tests
  $ DYLD_FRAMEWORK_PATH={������}/framework/build ruby -I../lib testall.rb

ñ�Υƥ��Ȥˤ�Test::Unit��ɬ�פǤ������Υץ������Ͼ�ά��ǽ�Ǥ���


== RubyCocoa�Υ��󥹥ȡ���

  $ sudo ruby install.rb install

�ʾ�ǥ��󥹥ȡ���ϴ�λ�Ǥ��������ޤǤμ��ǰʲ��Τ�Τ����󥹥ȡ���
����ޤ�����

: /Library/Frameworks/RubyCocoa.framework
  RubyCocoa�ե졼���� (����)

: /usr/lib/ruby/site_ruby/1.6/osx/ ����
  RubyCocoa�饤�֥�� (stub) 
  - addressbook.rb, appkit.rb, cocoa.rb, foundation.rb

: /usr/lib/ruby/site_ruby/1.6/powerpc-darwin6.0/rubycocoa.bundle
  RubyCocoa��ĥ�饤�֥�� (stub)

: '/Developer/ProjectBuilder Extras/' ����
  ProjectBuilder�Υƥ�ץ졼��
  * 'File Templates/Ruby'
  * 'Project Templates/Application/Cocoa-Ruby Document-based Application'
  * 'Project Templates/Application/Cocoa-Ruby Application'

: /Developer/Documentation/RubyCocoa
  �ɥ������ (HTML)

: /Developer/Examples/RubyCocoa
  ����ץ�ץ������


((<����°����ץ���Ƥߤ��|URL:trysamples.ja.html>)) �򻲹ͤ�
ư���ǧ���ƤߤƤ���������


== [FYI] �Х��ʥ�ѥå������󥰤������ʥ��󥹥ȡ��륪�ץ����

RubyCocoa�ΥХ��ʥ�ѥå���������Ȥ���������'ruby install.rb
config'�Υ��ץ���󤬤���ޤ���

  * --install-prefix : 
    ��ĥ�饤�֥��ȥ饤�֥��Υ��󥹥ȡ�����˱ƶ�
  * --install-root :
    �ե졼�������ƥ�ץ졼�ȡ��ɥ�����ȡ�����ץ�Υ��󥹥ȡ�����˱ƶ�

=== ��

  $ ruby -r rbconfig -e 'p Config::CONFIG["prefix"]'
  "/usr"
  $ ruby install.rb config \
      --install-prefix=/tmp/build/usr --install-root=/tmp/build
  $ ruby install.rb setup
  $ sudo ruby install.rb install

��̤Ȥ��ưʲ��ξ���(����)���󥹥ȡ��뤵��ޤ���

  /tmp/build/usr/lib/ruby/site_ruby/1.6/osx/addressbook.rb
  /tmp/build/usr/lib/ruby/site_ruby/1.6/osx/appkit.rb
  /tmp/build/usr/lib/ruby/site_ruby/1.6/osx/cocoa.rb
  /tmp/build/usr/lib/ruby/site_ruby/1.6/osx/foundation.rb
  /tmp/build/usr/lib/ruby/site_ruby/1.6/powerpc-darwin6.0/rubycocoa.bundle
  /tmp/build/Library/Frameworks/RubyCocoa.framework
  /tmp/build/Developer/ProjectBuilder Extras/File Templates/Ruby
  /tmp/build/Developer/ProjectBuilder Extras/Project Templates/ \
          Application/Cocoa-Ruby Application
  /tmp/build/Developer/ProjectBuilder Extras/Project Templates/ \
          Application/Cocoa-Ruby Document-based Application
  /tmp/build/Developer/Examples/RubyCocoa
  /tmp/build/Developer/Documentation/RubyCocoa


== RubyCocoa 0.4.0 �� Ruby 1.6.8 �Ǻ��Ȥ���������

((*Ruby 1.6.8*)) �� RubyCocoa 0.4.0 �򥽡������鹽�ۤ���Ȥ���

  ruby install.rb config

��¹Ԥ���� Segmentation fault ��ȯ�����ޤ�������������褹�뤿�ᡢ
rubycocoa-0.4.0.tgz ��Ÿ���������ȡ����Τ褦��
((<�ѥå�|URL:http://www.imasy.or.jp/%7ehisa/mac/rubyosx/files/ruco0.4.0-fw-post-config.patch>))
�򤢤ƤƤ���������

  $ cd {rubycocoa-0.4.0}
  $ patch -p0 < ruco0.4.0-fw-post-config.patch

�ѥå������Ƥϰʲ����̤�Ǥ���

  diff -u -b -u -r1.4 post-config.rb
  --- framework/post-config.rb	19 Dec 2002 08:41:50 -0000	1.4
  +++ framework/post-config.rb	11 Jan 2003 14:02:17 -0000
  @@ -12,10 +12,9 @@
     $stderr.puts "create #{File.expand_path(dst_fname)} ..."
     File.open(dst_fname, 'w') do |dstfile|
       IO.foreach(src_path) do |line|
  -      line = line.gsub( /\bID\b/, 'RB_ID' )
  -      line = line.gsub( /\bT_DATA\b/, 'RB_T_DATA' )
  -      line = line.gsub( /\bintern.h\b/, "#{new_filename_prefix}intern.h" )
  -      dstfile.puts line
  +      line.gsub!( /\b(ID|T_DATA)\b/, 'RB_\1' )
  +      line.gsub!( /\bintern\.h\b/, "#{new_filename_prefix}intern.h" )
  +      dstfile.puts( line )
       end
     end
   end


== ��ȯư���ǧ�Ķ�

�ʲ��δĶ��ǳ�ȯư���ǧ�򤷤Ƥ��ޤ���

* PowerMacintosh G4/400/384MB or iBook G3/600/384MB
* Mac OS X 10.2.3
* DevTools 10.2
* ruby-1.6.7 (pre-installed in Mac OS X 10.2)
* ruby-1.8 (preview 1 from cvs server)

== �ǤϤ��ڤ��ߤ�������

���ۡ������ǥ�����ơ����䡢����ʤɤʤ�Ǥⵤ�ڤ˶����Ƥ���������


$Date$