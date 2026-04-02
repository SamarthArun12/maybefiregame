local HModule = {}

function HModule.change(humanoid, mult, primary, IncDec)
	local factor = 1
	if IncDec == "Dec" then
		factor = -1
	end
	local change = 0
	if primary == true then
		change = .05 * mault * factor
	else
		change = .025 * mult * factor
	end
	humanoid.Health += change 
end

return HModule
