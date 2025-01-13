------------------------------------------------------------------------
-- runtime code
------------------------------------------------------------------------

require('lib.init')

-- setup player management
require('stdlib.event.player').register_events(true)

-- setup events
require('scripts.event-setup')

-- setup remote interface
require('scripts.remote')

Framework.post_runtime_stage()
