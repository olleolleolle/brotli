require 'mkmf'
require 'fileutils'
require 'rbconfig'

$CPPFLAGS << ' -DOS_MACOSX' if RbConfig::CONFIG['host_os'] =~ /darwin|mac os/
$INCFLAGS << '-I./common -I./include'
create_makefile('brotli/brotli')

def acopy(dir)
  # source dir
  FileUtils.mkdir_p(File.expand_path(File.join(__dir__, dir)))
  # object dir
  FileUtils.mkdir_p(dir)

  brotli_dir = File.join(__dir__, '..', '..', 'vendor', 'brotli')

  if dir == 'include'
    files = Dir.glob(File.expand_path(File.join(brotli_dir, 'include', 'brotli', '*.[ch]')))
    FileUtils.cp_r File.join(brotli_dir, 'include', '.'), 'include', verbose: false
    srcs = files.map { |e| File.basename e }.select { |e| e.end_with?('.c') || e.end_with?('.h') }.map { |e| File.join('include', 'brotli', e) }
  else
    files = Dir.glob(File.expand_path(File.join(brotli_dir, dir, '**/*.[ch]')))
    FileUtils.cp_r files, 'common', verbose: false
    srcs = files.map { |e| File.basename e }.select { |e| e.end_with?('.c') || e.end_with?('.h')  }.map { |e| File.join('common', e) }
  end

  objs = srcs.select { |e| e.end_with?('.c') }.map { |e| e.sub(/\.c\z/, '.' + $OBJEXT) }
  [srcs, objs]
end

srcs = []
objs = []
%w(include common).each do |dir|
  a, b = acopy(dir)
  srcs.concat(a)
  objs.concat(b)
end

File.open('Makefile', 'r+') do |f|
  src = 'ORIG_SRCS = brotli.c buffer.c'
  obj = 'OBJS = brotli.o buffer.o'
  txt = f.read
        .sub(/^ORIG_SRCS = .*$/, src + ' ' + srcs.join(' '))
        .sub(/^OBJS = .*$/, obj + ' ' + objs.join(' '))
  f.rewind
  f.write txt
end
