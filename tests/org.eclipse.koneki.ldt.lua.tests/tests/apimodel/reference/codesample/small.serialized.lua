do
	local _ = {
		description = "",
		globalvars = {} --[[table: 0x8650b70]],
		shortdescription = " Small file to process\010 ",
		name = "small",
		returns = {
			{
				types = {
					{
						typename = "small",
						tag = "internaltyperef"
					} --[[table: 0x8652a58]]
				} --[[table: 0x8650b00]],
				description = "",
				tag = "return"
			} --[[table: 0x8650a60]]
		} --[[table: 0x8650b98]],
		types = {
			small = {
				fields = {} --[[table: 0x866da70]],
				name = "small",
				parent = nil --[[ref]],
				sourcerange = {
					min = 0,
					max = 49
				} --[[table: 0x866da98]],
				tag = "recordtypedef"
			} --[[table: 0x866d960]]
		}
		--[[table: 0x8650b48]],
		tag = "file"
	} --[[table: 0x8652a30]];
	_.types.small.parent = _;
	return _;
end