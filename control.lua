------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

require('lib.init')

-- setup player management
require('__stdlib__/stdlib/event/player').register_events(true)

-- setup events
require('scripts.event-setup')

-- other mods code
require('framework.other-mods').runtime()
