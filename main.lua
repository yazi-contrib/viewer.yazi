--- Centered, enlarged previews of images, SVGs and PDF pages.
---
--- Yazi draws an image from the top left corner of the preview pane and never makes it larger, so a
--- small image stays small and sits in the corner. This plugin runs the built-in previewer that its
--- first argument names (image, pdf, svg) and gives the image it draws a larger copy, centered in
--- the pane. Yazi's own preloader still makes the cache that the built-in previewer reads.
---
--- Options are arguments of the previewer rule in yazi.toml, as Yazi runs a previewer in a Lua state
--- of its own, where `setup` of init.lua has not run:
---
---   { mime = "image/*", run = "viewer image --max_up=4 --fill=0.75" }

local M = {}

-- max_up: how many times larger than it is an image can be drawn, a small image is soft when it is
-- larger. fill: the part of the pane that an image fills, the rest is the margin around it
local DEFAULTS = { max_up = 4, fill = 0.75 }

-- the options of a run, from its arguments: a number that is not valid is the default
local function options(args)
	local max_up = tonumber(args.max_up)
	local fill = tonumber(args.fill)
	return {
		max_up = (max_up and max_up >= 1) and max_up or DEFAULTS.max_up,
		fill = (fill and fill > 0 and fill <= 1) and fill or DEFAULTS.fill,
	}
end

-- the image made larger, in a folder of the temporary files, which a reboot clears
local function enlarged(url, factor)
	local cha = fs.cha(url)
	local key = ya.hash(
		string.format("%s//%s//%s//%.2f", tostring(url), cha and cha.len or 0, cha and cha.mtime or 0, factor)
	)
	local dir = (os.getenv("TMPDIR") or "/tmp") .. "/yazi-viewer"
	local dest = Url(dir .. "/" .. key .. ".png")
	if fs.cha(dest) then
		return dest
	end

	Command("mkdir"):arg({ "-p", dir }):status()
	local status = Command("magick")
		:arg({
			tostring(url),
			"-filter",
			"Lanczos",
			"-resize",
			string.format("%d%%", math.floor(factor * 100)),
			"PNG:" .. tostring(dest),
		})
		:status()
	if status and status.success then
		return dest
	end
end

-- ya.image_show takes the area of the pane: this gives it the part of the pane in the middle
local function install(config)
	local show = ya.image_show_original or ya.image_show
	ya.image_show_original = show
	ya.image_show = function(url, area)
		local info = ya.image_info(url)
		local cw, ch = rt.term.cell_size()
		if info and cw and ch and cw > 0 and ch > 0 then
			-- how many times the size of the image fills the part of the pane, and Yazi draws no
			-- image larger than max_width and max_height, so it is no more than that either
			local fit = math.min((area.w * cw) / info.w, (area.h * ch) / info.h) * config.fill
			local factor = math.min(fit, config.max_up, rt.preview.max_width / info.w, rt.preview.max_height / info.h)
			if factor > 1.1 then
				local big = enlarged(url, factor)
				local big_info = big and ya.image_info(big)
				if big_info then
					url, info, factor = big, big_info, 1
				end
			end
			-- an image larger than the part of the pane is drawn smaller
			local scale = math.min(1, factor)
			local cols = math.min(area.w, math.ceil(info.w * scale / cw))
			local rows = math.min(area.h, math.ceil(info.h * scale / ch))
			area = ui.Rect {
				x = area.x + math.floor((area.w - cols) / 2),
				y = area.y + math.floor((area.h - rows) / 2),
				w = cols,
				h = rows,
			}
		end
		return show(url, area)
	end
end

function M:peek(job)
	install(options(job.args))
	local name = job.args[1]
	if not name then
		return ya.preview_widget(job, Err("viewer: the previewer to run is missing, use `run = \"viewer image\"`"))
	end
	return require(name):peek(job)
end

function M:seek(job)
	local name = job.args[1]
	if name then
		return require(name):seek(job)
	end
end

return M
