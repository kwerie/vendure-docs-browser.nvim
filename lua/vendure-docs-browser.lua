local M = {}
local uv = vim.uv or vim.loop
local LLMS_URL = "https://docs.vendure.io/llms.txt"
local CACHE_TTL = 3600 -- 1 hour

local initialized = false
local llms_cache_dir = vim.fn.stdpath("cache") .. "/vendure-docs-browser"
if not uv.fs_stat(llms_cache_dir) then
	uv.fs_mkdir(llms_cache_dir, tonumber("755", 8))
end
local local_llms_path = llms_cache_dir .. "/llms.txt"

-- Telescope dependencies
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function is_vendure_project()
	local root = vim.fs.find("node_modules", { upward = true, stop = uv.os_homedir() })[1]

	if not root then
		return false
	end

	local vendure_path = root .. "/@vendure"

	local stat = uv.fs_stat(vendure_path)
	return stat and stat.type == "directory"
end

local function fetch_llms(callback)
	-- Check if local file exists and is less than 1 hour old to prevent being blocked from fetching the file again.
	local stat = uv.fs_stat(local_llms_path)
	if stat and stat.type == "file" and (os.time() - stat.mtime.sec) < CACHE_TTL then
		-- File is less than 1 hour old, consider it fresh
		if callback then
			callback()
		end
		return
	end

	local has_fidget, progress = pcall(require, "fidget.progress")
	local handle

	if has_fidget then
		handle = progress.handle.create({
			title = "Fetching LLMs",
			message = "Downloading...",
			lsp_client = { name = "vendure-docs-browser" },
		})
	end

	local job_id = vim.fn.jobstart({ "curl", "-sSL", LLMS_URL, "-o", local_llms_path }, {
		on_exit = function(_, code)
			vim.schedule(function()
				if code == 0 then
					if handle then
						handle.message = "Done"
						handle:finish()
					end
					if callback then
						callback()
					end
				else
					if handle then
						handle.message = "Failed (exit " .. code .. ")"
						handle:cancel()
					end
				end
			end)
		end,
	})

	if job_id == 0 then
		vim.notify("curl not found. Please install curl to use vendure-docs-browser.", vim.log.levels.ERROR)
		if handle then
			handle:cancel()
		end
	end
end

local function parse_llms_file()
	local entries = {}

	local success, result = pcall(vim.fn.readfile, local_llms_path)

	if not success then
		vim.notify("Failed to read llms.txt: " .. result, vim.log.levels.ERROR)
		return {}
	end

	for _, line in ipairs(result) do
		-- Third param is an optional description, ignored for now because it is equal to the title as of 2026-02-17
		local title, url, _ = line:match("%[(.-)%]%((https?://[^%s)]+)%)%:%s*(.*)")

		if title and url then
			table.insert(entries, {
				title = title,
				url = url,
			})
		end
	end

	return entries
end

function M.browse_docs()
	if not initialized then
		fetch_llms(function()
			initialized = true
			M.browse_docs()
		end)
		return
	end

	local docs = parse_llms_file()

	if vim.tbl_isempty(docs) then
		vim.notify("No Vendure docs found in llms.txt", vim.log.levels.WARN)
		return
	end

	pickers
		.new({}, {
			prompt_title = "Vendure Docs",
			finder = finders.new_table({
				results = docs,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.title,
						ordinal = entry.title,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local sel = action_state.get_selected_entry()
					if not sel then
						return
					end
					actions.close(prompt_bufnr)
					local docsUrl = sel.value.url:gsub("%.md$", "")
					vim.ui.open(docsUrl)
				end)
				return true
			end,
		})
		:find()
end

function M.setup()
	vim.api.nvim_create_user_command("BrowseVendureDocs", M.browse_docs, {})

	vim.api.nvim_create_autocmd("BufReadPre", {
		callback = function()
			if initialized or not is_vendure_project() then
				return
			end

			fetch_llms(function()
				initialized = true
			end)
		end,
	})
end

return M
