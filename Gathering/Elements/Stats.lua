local Name, AddOn = ...
local Gathering = AddOn.Gathering

-- Generic counting of numbers
local SessionStat = {}

function Gathering:AddStat(stat, value)
        if (not GatheringStats) then
                GatheringStats = {}
        end

        local Amount = value or 1

        GatheringStats[stat] = (GatheringStats[stat] or 0) + Amount
        SessionStat[stat] = (SessionStat[stat] or 0) + Amount
end

Gathering.SessionStats = SessionStat
