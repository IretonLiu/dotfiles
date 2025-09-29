local function get_python_path()
	-- 1. If inside a conda env, use it
	if vim.env.CONDA_PREFIX then
		return vim.env.CONDA_PREFIX .. "/bin/python"
	end

	-- 2. If a venv is active
	if vim.env.VIRTUAL_ENV then
		return vim.env.VIRTUAL_ENV .. "/bin/python"
	end

	-- 3. If there's a .venv folder in the project
	local cwd = vim.fn.getcwd()
	if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
		return cwd .. "/.venv/bin/python"
	end

	-- 4. Poetry-managed env
	if vim.fn.executable("poetry") == 1 then
		local venv = vim.fn.trim(vim.fn.system("poetry env info --path"))
		if venv ~= "" then
			return venv .. "/bin/python"
		end
	end

	-- 5. Pyenv
	if vim.fn.executable("pyenv") == 1 then
		local venv = vim.fn.trim(vim.fn.system("pyenv which python"))
		if venv ~= "" then
			return venv
		end
	end

	-- 6. Fallback
	return "python3"
end

require("dap-python").setup(get_python_path())
