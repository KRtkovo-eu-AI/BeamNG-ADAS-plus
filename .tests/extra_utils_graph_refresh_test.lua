local laura = require('laura')
local describe = laura.describe
local it = laura.it
local expect = laura.expect

-- A map that builds its road graph while driving (BeamNG.Earth) replaces map.getMap() and the vehicle map data after
-- extraUtils cached them: a node added since must still resolve, and a node no graph has must give nil, not throw.
local MODULE = 'scripts/driver_assistance_angelo234/extraUtils'

local function load(world)
  package.loaded[MODULE] = nil
  package.loaded['lua/common/luaProfiler'] = true
  package.loaded['lua/vehicle/mapmgr'] = world.mapmgr
  _G.vec3 = function(p) return { x = p.x, y = p.y, z = p.z } end
  _G.map = { getMap = function() return { nodes = world.nodes } end, findClosestRoad = function() return nil end }
  return require(MODULE)
end

describe('extraUtils on a road graph rebuilt while driving', function()
  it('finds a waypoint the graph gained after the mission start', function()
    local world = { nodes = { a = { pos = { x = 1, y = 2, z = 3 } } },
      mapmgr = { mapData = { graph = {}, positions = { a = { x = 1, y = 2, z = 3 } } } } }
    local utils = load(world)
    -- the map rebuilds its graph: new tables, a node the cached ones do not have
    world.nodes = { a = world.nodes.a, b = { pos = { x = 7, y = 8, z = 9 } } }
    world.mapmgr.mapData = { graph = {}, positions = { a = { x = 1, y = 2, z = 3 }, b = { x = 7, y = 8, z = 9 } } }
    local p = utils.getWaypointPosition('b')
    expect(p ~= nil).toEqual(true)
    expect(p and p.x).toEqual(7)
  end)

  it('returns nil for a node no graph has', function()
    local world = { nodes = {}, mapmgr = { mapData = { graph = {}, positions = {} } } }
    local utils = load(world)
    expect(utils.getWaypointPosition('missing')).toEqual(nil)
  end)
end)
