class dirtree {
  # rubysitedir = /usr/lib/ruby/site_ruby/1.8
  $dirtree = dirtree($::rubysitedir)

  # $dirtree = ['/usr', '/usr/lib', '/usr/lib/ruby', '/usr/lib/ruby/site_ruby', '/usr/lib/ruby/site_ruby/1.8',]
  ensure_resource('dir', $dirtree, {'ensure' => 'directory'})
}
