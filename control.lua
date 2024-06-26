------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

require('lib.init')

-- setup player management
require('__stdlib__/stdlib/event/player').register_events(true)

-- setup events
require('scripts.event-setup')

-- setup remote interface
require('scripts.remote')

-- other mods code
require('framework.other-mods').runtime()
