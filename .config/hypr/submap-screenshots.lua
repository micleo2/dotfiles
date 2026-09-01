-- Screenshot/record map: tap SUPER+PRINT to enter a submap for capturing screenshots and recordings.
local submap_builder = require("submap-builder")

local submap_options_per_key = {
	o = { label = "ocr region", exec_cmd = "~/dotfiles/scripts/ocr-region-select.sh" },
	p = { label = "hyprpicker", exec_cmd = "hyprpicker -a" },
	-- The 0.1s delay gives the submap time to reset and the (no_anim)
	-- overlay time to unmap before the capture starts, so the overlay
	-- never ends up in screenshots/recordings.
	i = { label = "instant-replay", exec_cmd = "sleep 0.1 && gsr-ui-cli replay-save" },
	r = { label = "toggle-recording", exec_cmd = "sleep 0.1 && gsr-ui-cli toggle-record" },
	["SHIFT+R"] = { label = "toggle-recording-region", exec_cmd = "sleep 0.1 && gsr-ui-cli toggle-record-region" },
	s = { label = "screenshot", exec_cmd = "sleep 0.1 && gsr-ui-cli take-screenshot" },
	["SHIFT+S"] = { label = "screenshot-region", exec_cmd = "sleep 0.1 && gsr-ui-cli take-screenshot-region" },
}

submap_builder.define_submap("screenshots", "SUPER+PRINT", submap_options_per_key)
