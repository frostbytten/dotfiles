local docgen = {}

local function get_node_text(node, buf)
    return vim.split(vim.treesitter.get_node_text(node, buf) or "", "\n")
end

-- Create the directory if it does not exist
docgen.output_dir = "wiki"
pcall(vim.fn.mkdir, docgen.output_dir)

local scan = require("plenary.scandir")

require("neorg").setup({
    load = {
        ["core.defaults"] = {},
        ["core.gtd.base"] = {},
        ["core.integrations.treesitter"] = {
            config = {
                configure_parsers = false,
            },
        },
    },
})

-- Start neorg
neorg.org_file_entered(false)

-- Extract treesitter utility functions provided by Neorg and nvim-treesitter.ts_utils
local ts = neorg.modules.get_module("core.integrations.treesitter")
local ts_utils = ts.get_ts_utils()

-- Store all parsed modules in this variable
local modules = {}

--- Get the list of every module.lua file in neorg
--- @return table
docgen.find_modules = function()
    local path = vim.fn.getcwd()
    local neorg_modules = "lua/neorg/modules"

    return scan.scan_dir(path .. "/" .. neorg_modules, { search_pattern = "module.lua$" })
end

--- Get bufnr from a filepath
--- @param path string
--- @return number
docgen.get_buf_from_file = function(path)
    local uri = vim.uri_from_fname(path)
    local buf = vim.uri_to_bufnr(uri)

    return buf
end

--- Get the first comment (at line 0) from a module and get it's content
--- @param path string
--- @return number, table #Returns the buffer and the table of comment
docgen.get_module_top_comment = function(path)
    local buf = docgen.get_buf_from_file(path)
    local node = ts.get_first_node_recursive("comment", { buf = buf, ft = "lua" })

    if not node then
        return
    end

    -- Verify if it's the first line
    local start_row = ts_utils.get_node_range(node)
    if start_row ~= 0 then
        return
    end

    local comment = get_node_text(node, buf)

    -- Stops execution if it's not a multiline comment
    if not comment[1] == "--[[" or not comment[#comment] == "--]]" then
        return
    end

    -- Removes first and last braces
    table.remove(comment, 1)
    table.remove(comment, #comment)

    return buf, comment
end

--- Parses the query from a buffer
--- @param buf number
--- @param query string
--- @return table
docgen.get_module_queries = function(buf, query)
    vim.api.nvim_set_current_buf(buf)

    return vim.treesitter.parse_query("lua", query)
end

--- The actual code that generates a md file from a template
--- @param buf number
--- @param path string
--- @param comment table
docgen.generate_md_file = function(buf, path, comment, main_page)
    local module = {}
    if not main_page then
        module = dofile(path)
        neorg.modules.load_module(module.name)
        module = neorg.modules.loaded_modules[module.name].real()

        for _, import in ipairs(module.setup().imports or {}) do
            local import_path = vim.fn.fnamemodify(path, ":p:h") .. "/" .. import .. ".lua"
            local imported_extension = dofile(import_path).real()
            imported_extension.path = import_path
            imported_extension.is_extension = true
            modules[imported_extension.name] = imported_extension
        end

        module.show_module = module.show_module or true
        modules[module.name] = module
    end

    local structure
    if main_page == "Home" then
        structure = {
            '<div align="center">',
            "",
            "# Welcome to the Neorg wiki!",
            "Want to know how to properly use Neorg? Your answers are contained here.",
            "",
            "</div>",
            "",
            "# Using Neorg",
            "",
            "At first configuring Neorg might be rather scary. I have to define what modules I want to use in the `require('neorg').setup()` function?",
            "I don't even know what the default available values are!",
            "Don't worry, an installation guide is present [here](https://github.com/nvim-neorg/neorg/wiki/Installation), so go ahead and read it!",
            "",
            "# Contributing to Neorg",
            "",
            "Neorg is a very big and powerful tool behind the scenes - way bigger than it may initially seem.",
            "Modules are its core foundation, and building modules is like building lego bricks to form a massive structure!",
            "There's a whole tutorial dedicated to making modules [right here](https://github.com/nvim-neorg/neorg/wiki/Creating-Modules).",
            "There everything you need will be explained - think of it as a walkthrough.",
            "# Module naming convention",
            "Neorg provides default modules, and users can extend Neorg by creating community modules.",
            "We agreed on a module naming convention, and it should be used as is.",
            "This convention should help users know at a glance what function the module serves in the grand scheme of things.",
            "- Core modules: `core.*`",
            "- Integrations with 3rd party software that are emdebbed in neorg: `core.integrations.*`",
            "- External modules: `external.*`",
            "- Integrations with 3rd party software that aren't emdebbed in neorg: `external.integrations.*`",
            "",
            "# Default Modules",
            "",
            function()
                local core_defaults = modules["core.defaults"]
                local link = "[`core.defaults`](https://github.com/nvim-neorg/neorg/wiki/"
                    .. core_defaults.filename
                    .. ")"
                return {
                    "Neorg comes with some default modules that will be automatically loaded if you require the "
                        .. link
                        .. " module:",
                }
            end,
            "",
            function()
                local core_defaults = modules["core.defaults"]

                if not core_defaults then
                    return
                end

                local res = {}
                for module, config in pairs(modules) do
                    if vim.tbl_contains(core_defaults.config.public.enable, config.name) and config.show_module then
                        local insert
                        if config.filename then
                            insert = "- [`"
                                .. config.name
                                .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                                .. config.filename
                                .. ")"
                        else
                            insert = "- `" .. module .. "`"
                        end
                        if config.summary then
                            insert = insert .. " - " .. config.summary
                        else
                            insert = insert .. " - undocumented module"
                        end

                        table.insert(res, insert)
                    end
                end
                return res
            end,
            "",
            "# Complementary Modules",
            "",
            "Neorg comes with its own builtin modules to make development easier. Below is a list of all modules that are not required by default:",
            "",
            function()
                local res = {}
                local core_defaults = modules["core.defaults"]

                if not core_defaults then
                    return
                end

                for module, config in pairs(modules) do
                    if
                        not config.is_extension
                        and not vim.tbl_contains(core_defaults.config.public.enable, config.name)
                        and config.show_module
                    then
                        local insert
                        if config.filename then
                            insert = "- [`"
                                .. config.name
                                .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                                .. config.filename
                                .. ")"
                        else
                            insert = "- `" .. module .. "`"
                        end
                        if config.summary then
                            insert = insert .. " - " .. config.summary
                        else
                            insert = insert .. " - undocumented module"
                        end

                        table.insert(res, insert)
                    end
                end
                return res
            end,
            "",
            "# Developer modules",
            "",
            "These are modules that are only meant for developers. They are generally required in other modules:",
            "",
            function()
                local res = {}
                local core_defaults = modules["core.defaults"]

                if not core_defaults then
                    return
                end

                for module, config in pairs(modules) do
                    if
                        not config.is_extension
                        and not vim.tbl_contains(core_defaults.config.public.enable, config.name)
                        and not config.show_module
                    then
                        local insert
                        if config.filename then
                            insert = "- [`"
                                .. config.name
                                .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                                .. config.filename
                                .. ")"
                        else
                            insert = "- `" .. module .. "`"
                        end
                        if config.summary then
                            insert = insert .. " - " .. config.summary
                        else
                            insert = insert .. " - undocumented module"
                        end

                        table.insert(res, insert)
                    end
                end
                return res
            end,
        }
    elseif main_page == "_Sidebar" then
        structure = {
            "<div align='center'>",
            "",
            "# :star2: Neorg",
            "</div>",
            "",
            "### Setting Up",
            "- [How do I configure modules?](https://github.com/nvim-neorg/neorg/wiki/Configuring-Modules)",
            "- [User Keybinds](https://github.com/nvim-neorg/neorg/wiki/User-Keybinds)",
            "- [User Callbacks](https://github.com/nvim-neorg/neorg/wiki/User-Callbacks)",
            "- [Customizing Icons](https://github.com/nvim-neorg/neorg/wiki/Concealer)",
            "### For the programmer",
            "- [Writing my own module](https://github.com/nvim-neorg/neorg/wiki/Creating-Modules)",
            "- [Hotswapping modules](https://github.com/nvim-neorg/neorg/wiki/Hotswapping-Modules)",
            "- [Difference between module.public and module.config.public](https://github.com/nvim-neorg/neorg/wiki/Public-vs-Public-Config)",
            "- [Metamodules](https://github.com/nvim-neorg/neorg/wiki/Metamodules)",
            "",
            "<details>",
            "<summary>Inbuilt modules:</summary>",
            "",
            function()
                local res = {}
                local names = {}

                for n, config in pairs(modules) do
                    if config.is_extension ~= true then
                        table.insert(names, n)
                    end
                end
                table.sort(names)
                for _, name in ipairs(names) do
                    local config = modules[name]
                    if config.show_module then
                        local insert = ""
                        if config.filename then
                            insert = insert
                                .. "- [`"
                                .. config.name
                                .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                                .. config.filename
                                .. ")"
                        else
                            insert = insert .. "- `" .. name .. "`"
                        end

                        table.insert(res, insert)
                    end
                end
                return res
            end,
            "</details>",
        }
    else
        structure = {
            function()
                return { module.title and "# " .. module.title or ("# The `" .. module.name .. "` Module") }
            end,
            function()
                return { (module.summary or "*No summary provided*") }
            end,
            "",
            "## Overview",
            "<comment>",
            "",
            "## Configuration",
            {
                query = [[
                    (assignment_statement
                        (variable_list) @_name
                        (#eq? @_name "module.config.public")
                    ) @declaration
                ]],
                callback = function(main_query)
                    local results = {}

                    local tree = vim.treesitter.get_parser(buf, "lua"):parse()[1]

                    if not tree then
                        return {}
                    end

                    local has_capture = false

                    for id, public_config in main_query:iter_captures(tree:root(), buf) do
                        if main_query.captures[id] == "declaration" then
                            has_capture = true

                            local query = vim.treesitter.parse_query(
                                "lua",
                                [[
                                (
                                    (comment)+ @comment
                                    .
                                    (field
                                        name: [
                                            (identifier) @identifier
                                            (string
                                                content: ("string_content") @identifier
                                            )
                                        ]
                                        value: (_) @value
                                    ) @field
                                )
                            ]]
                            )

                            local indent_level = 0
                            local comments = {}
                            local identifier = nil
                            local values = {}

                            for id, parsed_config_option in query:iter_captures(public_config, buf) do
                                local capture = query.captures[id]

                                if capture == "field" then
                                    indent_level = ts.get_node_range(parsed_config_option).column_start + 1
                                elseif capture == "identifier" then
                                    identifier = ts.get_node_text(parsed_config_option)
                                elseif capture == "comment" then
                                    table.insert(
                                        comments, --[[ this is required -> ]]
                                        "" .. ts.get_node_text(parsed_config_option):gsub("^%-+%s*", "")
                                    )
                                elseif capture == "value" then
                                    if parsed_config_option:type() ~= "table_constructor" then
                                        if parsed_config_option:type() == "function_definition" then
                                            values = {
                                                "  Default value: `function" .. ts.get_node_text(
                                                    parsed_config_option:named_child(0)
                                                ) .. "`",
                                            }
                                        else
                                            values = {
                                                "  Default value: `" .. ts.get_node_text(parsed_config_option) .. "`",
                                            }
                                        end
                                    else
                                        table.insert(values, "  Default Value:")
                                        table.insert(values, "  ```lua")

                                        local text = neorg.lib.map(
                                            get_node_text(parsed_config_option),
                                            function(_, value)
                                                return "  " .. value
                                            end
                                        )
                                        for i = 2, #text do
                                            text[i] = text[i]:sub(indent_level)
                                        end

                                        vim.list_extend(values, text)
                                        table.insert(values, "  ```")
                                    end
                                end

                                if not vim.tbl_isempty(comments) and identifier and not vim.tbl_isempty(values) then
                                    table.insert(results, "")

                                    table.insert(results, "<dl>")

                                    table.insert(results, "<dt>")
                                    table.insert(results, identifier)
                                    table.insert(results, "</dt>")

                                    table.insert(results, "")

                                    table.insert(results, "<dd>")
                                    vim.list_extend(results, comments)

                                    table.insert(results, "")

                                    vim.list_extend(results, values)
                                    table.insert(results, "</dd>")

                                    table.insert(results, "</dl>")

                                    table.insert(results, "")

                                    indent_level = 0
                                    comments = {}
                                    identifier = nil
                                    values = {}
                                end
                            end
                        end
                    end

                    if not has_capture then
                        table.insert(results, "This module exposes no customization options.")
                        return results
                    end

                    return results
                end,
            },
            "## Keybinds",
            function()
                -- TODO: Add metadata to each keybind in a k-v pair
                -- with descriptions of the keybind and their default
                -- values.
                local keybinds = module.keybinds

                if not keybinds or vim.tbl_isempty(keybinds) then
                    return {
                        "This module defines no keybinds."
                    }
                end

                local output = {}

                for _, keybind in ipairs(keybinds) do
                    table.insert(output, "- `" .. keybind .. "`")
                end

                return output
            end,
            "",
            "## How to Apply",
            function()
                local core_defaults = modules["core.defaults"]

                if not core_defaults then
                    return
                end

                if
                    not vim.tbl_isempty(vim.tbl_filter(function(elem)
                        return elem == module.name
                    end, core_defaults.config.public.enable or {}))
                then
                    return {
                        "- This module is already present in the [`core.defaults`](https://github.com/nvim-neorg/neorg/wiki/"
                            .. core_defaults.filename
                            .. ") metamodule.",
                        "  You can load the module with:",
                        "  ```lua",
                        '  ["core.defaults"] = {},',
                        "  ```",
                        "  In your Neorg setup.",
                    }
                end
            end,
            "- To manually load the module, place this code in your Neorg setup:",
            "  ```lua",
            '  ["' .. module.name .. '"] = {',
            "     config = { -- Note that this table is optional and doesn't need to be provided",
            "         -- Configuration here",
            "     }",
            "  }",
            "  ```",
            "  Consult the [configuration](#Configuration) section to see how you can configure `"
                .. module.name
                .. "` to your liking.",
            "",
            "---",
            "",
            "# Technical Information",
            "## Developer Usage",
            "### Public API",
            "This segment will detail all of the functions `"
                .. module.name
                .. "` exposes. All of these functions reside in the `public` table.",
            "",
            function()
                local api = neorg.modules.get_module(module.name)

                -- sort api in order to not shuffle each time we want to commit
                table.sort(api)

                local results = {}

                if not vim.tbl_isempty(api) then
                    for function_name, item in pairs(api) do
                        if type(item) == "function" then
                            table.insert(results, "- `" .. function_name .. "`")
                        end
                    end
                    if #results == 0 then
                        table.insert(results, "No public functions exposed.")
                    end

                    table.insert(results, "")
                end

                return results
            end,
            "### Examples",
            {
                query = [[
                (assignment_statement
                    (variable_list
                        name: (dot_index_expression) @_name
                        (#eq? @_name "module.examples")
                    )
                ) @declaration
            ]],

                callback = function(main_query)
                    if vim.tbl_isempty(module.examples) then
                        return { "None Provided" }
                    end

                    local tree = vim.treesitter.get_parser(buf, "lua"):parse()[1]
                    local result = {}
                    local index = 0

                    for variable_declaration_id, variable_declaration in main_query:iter_captures(tree:root(), buf) do
                        if main_query.captures[variable_declaration_id] == "declaration" then
                            local query = vim.treesitter.parse_query(
                                "lua",
                                [[
                            (table_constructor
                                (field
                                    name: [
                                        (identifier)
                                        (string)
                                    ] @identifier
                                    value: (function_definition
                                        parameters: (parameters)
                                        body: (block)
                                    )
                                )
                            )
                        ]]
                            )

                            for id, node in query:iter_captures(variable_declaration, buf) do
                                local capture = query.captures[id]

                                if capture == "identifier" then
                                    index = index + 1
                                    local identifier_text = ts.get_node_text(node)
                                    identifier_text = identifier_text:gsub("[\"'](.+)[\"']", "%1") or identifier_text

                                    result[index] = {
                                        "#### " .. identifier_text,
                                        "```lua",
                                    }

                                    local body_node = node:next_named_sibling():named_child(1)
                                    local body_node_column = ts.get_node_range(body_node).column_start
                                    local body_text = vim.split(vim.treesitter.get_node_text(body_node, buf), "\n")

                                    table.insert(result[index], body_text[1])

                                    for i = 2, #body_text do
                                        table.insert(result[index], body_text[i]:sub(body_node_column + 1))
                                    end

                                    table.insert(result[index], "```")
                                    table.insert(result[index], "")
                                end
                            end
                        end
                    end

                    return vim.tbl_flatten(result)
                end,
            },
            "",
            "## Extra Info",
            "### Version",
            "This module supports at least version **" .. module.public.version .. "**.",
            "The current Neorg version is **" .. neorg.configuration.version .. "**.",
            "",
            "### Imports",
            function()
                local imports = module.setup().imports

                if not imports or vim.tbl_isempty(imports) then
                    return { "This module does not import any other files." }
                end

                local ret = {}

                for _, import in ipairs(imports) do
                    local import_module = modules[module.name .. "." .. import]

                    if not import_module then
                        return
                    end

                    local trimmed = import_module.path:sub(import_module.path:find("/lua/") + 1, -1)

                    table.insert(
                        ret,
                        "- [`"
                            .. module.name
                            .. "."
                            .. import
                            .. "`](https://github.com/nvim-neorg/neorg/tree/main/"
                            .. trimmed
                            .. ")"
                    )
                end

                return ret
            end,
            "",
            "### Requires",
            function()
                local required = module.setup().requires

                if not required or vim.tbl_isempty(required) or not modules[required[1]] then
                    return { "This module does not require any other modules to operate." }
                end

                local ret = {}

                for _, name in ipairs(required) do
                    if modules[name] and modules[name].filename then
                        modules[name].required_by = modules[name].required_by or {}
                        table.insert(modules[name].required_by, module.name)

                        ret[#ret + 1] = "- [`"
                            .. name
                            .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                            .. modules[name].filename
                            .. ") - "
                            .. (modules[name].summary or "no description")
                    else
                        ret[#ret + 1] = "- `" .. name .. "` - undocumented module"
                    end
                end

                return ret
            end,
            "",
            "### Required by",
            function()
                if not module.required_by or vim.tbl_isempty(module.required_by) then
                    return { "This module isn't required by any other module." }
                end

                local ret = {}

                for _, name in ipairs(module.required_by) do
                    if modules[name] and modules[name].filename then
                        ret[#ret + 1] = "- [`"
                            .. name
                            .. "`](https://github.com/nvim-neorg/neorg/wiki/"
                            .. modules[name].filename
                            .. ") - "
                            .. (modules[name].summary or "no description")
                    else
                        ret[#ret + 1] = "- `" .. name .. "` - undocumented module"
                    end
                end

                return ret
            end,
        }
    end

    if (not comment or #comment == 0) and not main_page then
        return
    end

    local oldkey
    local arguments = {}

    if not main_page then
        for i, line in ipairs(comment) do
            if line:match("^%s*---$") then
                comment = vim.list_slice(comment, i + 1)
                break
            end

            local key, value = line:match("^%s*([%w%s]+)%:%s+(.+)$")

            if key and value then
                key = key:lower():gsub("%s", "_")
                arguments[key] = value
                oldkey = key
            elseif not line:match("^%s*$") and oldkey then
                arguments[oldkey] = arguments[oldkey] .. " " .. vim.trim(line)
            end
        end
    end

    if not arguments.file and not main_page then
        return
    end

    -- Perform linting on both the summary and title
    local function lint(input)
        if not input then
            return
        end

        local error_prefix = "Error in " .. module.name .. ": '" .. input .. "' "
        assert(input:sub(-1, -1) == ".", error_prefix .. "didn't have a full stop at the end of the sentence.")
        assert(
            not input:find("neorg"),
            error_prefix .. "had a lowercase 'neorg' word. Type 'Neorg' with an uppercase N"
        )

        return input
    end

    -- Populate the module with some extra info
    module.filename = arguments.file or main_page
    module.summary = lint(arguments.summary)
    module.title = arguments.title
    -- Do not show the module on sidebar and Home page
    module.show_module = arguments.internal ~= "true"

    -- Construct the desired filename
    local output_filename = module.filename .. ".md"

    -- If there are any keybinds for the current module place them in
    if modules["core.keybinds"] then
        local keybinds = {}

        for keybind in pairs(modules["core.keybinds"].public.keybinds) do
            if vim.startswith(keybind, module.name) then
                if not modules[keybind:sub(2 + module.name:len()):match("[^%.]+")] then
                    table.insert(keybinds, keybind)
                end
            end
        end

        module.keybinds = keybinds
    end

    local output = {}

    local function parse_reference_syntax(line)
        if not line then
            return
        end

        for match in line:gmatch("@([%-%.%w]+)") do
            line = line:gsub(
                "@" .. match:gsub("%p", "%%%1"),
                "https://github.com/nvim-neorg/neorg/wiki/" .. (modules[match] and modules[match].filename or "")
            )
        end

        return line
    end

    -- Generate structure
    for _, item in ipairs(structure) do
        if type(item) == "string" then
            item = parse_reference_syntax(item)

            if item == "<comment>" then
                for i, line in ipairs(comment) do
                    comment[i] = parse_reference_syntax(line)
                end

                vim.list_extend(output, comment)
            else
                table.insert(output, item)
            end
        elseif type(item) == "table" then
            local query = docgen.get_module_queries(buf, item.query)

            if query then
                local ret = item.callback(query)

                for _, str in ipairs(ret) do
                    table.insert(output, parse_reference_syntax(str))
                end
            end
        elseif type(item) == "function" then
            local function_output = item() or {}

            for i, line in ipairs(function_output) do
                function_output[i] = parse_reference_syntax(line)
            end

            vim.list_extend(output, function_output)
        end
    end

    local output_buffer = vim.api.nvim_create_buf(false, false)
    local output_path = vim.fn.getcwd() .. "/" .. docgen.output_dir .. "/" .. output_filename
    vim.api.nvim_buf_set_name(output_buffer, output_path)
    vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, output)
    vim.api.nvim_buf_call(output_buffer, function()
        vim.cmd("write!")
    end)
    vim.api.nvim_buf_delete(output_buffer, { force = true })
end

local files = docgen.find_modules()

for _ = 1, 2 do
    for _, file in ipairs(files) do
        local buf, comment = docgen.get_module_top_comment(file)

        if comment then
            docgen.generate_md_file(buf, file, comment)
        end
    end
end

docgen.generate_md_file(nil, nil, nil, "Home")
docgen.generate_md_file(nil, nil, nil, "_Sidebar")

return docgen
