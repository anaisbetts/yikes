# Block that describes debian package

p.packages << Pallet::Deb.new(p) do |deb|
	deb.depends    = %w{build-essential rake}
	deb.recommends = %w{fakeroot}
	deb.copyright  = 'COPYING'

	deb.section    = 'utils'
	deb.files      = [
		Installer.new('bin', '/usr/bin'),
		Installer.new('lib', '/usr/lib/yikes'),
		Installer.new('libexec', '/usr/lib/yikes/libexec'),
	]

	deb.docs = [
		Installer.new('doc',       'html'),
		Installer.new('Rakefile',  'examples'),
		Installer.new { Dir['[A-Z][A-Z]*'] },
	]
end
