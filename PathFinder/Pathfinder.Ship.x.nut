/**
 * A Ship Pathfinder.
 * 
 * Stitched together by Chruker, based partly on the road and rail pathfinders in the AI library and a shippathfinder by Yexo
 */
require("Graph.AyStar.x.nut");
class ShipPF
{
//	_aystar_class = import("graph.aystar", "", 6);
	_pathfinder = null;            ///< A reference to the used AyStar object.
	_running = null;
	_goal_estimate_tile = null;    ///< The tile we take as goal tile for the estimate function.
	_cost = null;                  ///< Used to change the costs.
	_cost_callbacks = null;        ///< Stores [callback, args] tuples for additional cost.

	_estimate_multiplier = null;   ///< Every estimate is multiplied by this value. Use 1 for a 'perfect' route, higher values for faster pathfinding.
	_max_path_length = null;       ///< The maximum length in tiles of the total route.
	_max_bridge_length = null;     ///< The maximum length of a bridge that will be build.

	_max_cost = null;              ///< The maximum cost for a route.
	_cost_tile = null;             ///< The cost for a single tile.
	_cost_canal = null;            ///< The added cost for building a canal.
	_cost_lock_per_tile = null;    ///< The added cost per tile for building a new lock.
	_cost_turn = null;             ///< The cost that is added to _cost_tile if the direction of canals change.
	_cost_demolition = null;       ///< The cost if demolition is required on a tile.
	_allow_demolition = null;      ///< Whether demolition is allowed.
	_cost_bridge_per_tile = null;  ///< The added cost per tile of a new bridge.



	static _LOCK = 1;
	static _BRIDGE = 2;



	constructor()
	{
		this._max_cost = 10000000;
		this._cost_tile = 100;
		this._cost_canal = 800;
		this._cost_lock_per_tile = 1500;
		this._cost_turn = 50;
		this._cost_bridge_per_tile = 1000;
		this._cost_demolition = 500;
		this._allow_demolition = false;
		this._max_bridge_length = 25;
		this._estimate_multiplier = 1;
//		this._pathfinder = this._aystar_class(this, this._Cost, this._Estimate, this._Neighbours, this._CheckDirection);
		this._pathfinder = AyStar(this, this._Cost, this._Estimate, this._Neighbours, this._CheckDirection);

		this._cost = this.Cost(this);
		this._cost_callbacks = [];
		this._running = false;
	}

	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 * @param max_length_multiplier The multiplier for the maximum route length.
	 * @param max_length_offset The minimum value of the maximum length.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals, ignored_tiles = [], max_length_multiplier = 0, max_length_offset = 10000);

	/**
	 * Register a new cost callback function that will be called with all args specified.
	 * The callback function must return an integer or an error will be thrown.
	 * @param callback The callback function. This function will be called with
	 * as parameters: self, old_path, new_tile, new_direction, new_params, custom_args. 
	 * @param custom_arg An extra argument for your cost callback.
	 */
	function RegisterCostCallback(callback, args) {
		this._cost_callbacks.push([callback, args]);
	}

	/**
	 * Try to find the path as indicated with InitializePath with the lowest cost.
	 * @param iterations After how many iterations it should abort for a moment.
	 *  This value should either be -1 for infinite, or > 0. Any other value
	 *  aborts immediatly and will never find a path.
	 * @return A route if one was found, or false if the amount of iterations was
	 *  reached, or null if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 * @see AyStar::FindPath()
	 */
	function FindPath(iterations);

	/**
	 * Build path return by FindPath.
	 * @param path AyStar.Path returned by FindPath.
	 * @param delay Sleep delay in ticks between succesfull build operation.
	 */
	function BuildPath(path, delay);
}

class ShipPF.Cost
{
	_main = null;

	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":            this._main._max_cost = val; break;
			case "tile":                this._main._cost_tile = val; break;
			case "canal":               this._main._cost_canal = val; break;
			case "lock_per_tile":       this._main._cost_lock_per_tile = val; break;
			case "turn":                this._main._cost_turn = val; break;
			case "bridge_per_tile":     this._main._cost_bridge_per_tile = val; break;
			case "demolition":          this._main._cost_demolition = val; break;
			case "allow_demolition":    this._main._allow_demolition = val; break;
			case "max_bridge_length":   this._main._max_bridge_length = val; break;
			case "estimate_multiplier": this._main._estimate_multiplier = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}

		return val;
	}

	function _get(idx)
	{
		switch (idx) {
			case "max_cost":            return this._main._max_cost;
			case "tile":                return this._main._cost_tile;
			case "canal":               return this._main._cost_canal;
			case "lock_per_tile":       return this._main._cost_lock_per_tile;
			case "turn":                return this._main._cost_turn;
			case "bridge_per_tile":     return this._main._cost_bridge_per_tile;
			case "demolition":          return this._main._cost_demolition;
			case "allow_demolition":    return this._main._allow_demolition;
			case "max_bridge_length":   return this._main._max_bridge_length;
			case "estimate_multiplier": return this._main._estimate_multiplier;
			default: throw("The index '" + idx + "' does not exist");
		}
	}

	constructor(main)
	{
		this._main = main;
	}
}

function ShipPF::InitializePath(sources, goals, ignored_tiles = [], max_length_multiplier = 0, max_length_offset = 10000)
{
	/* The tile closest to the first source tile is set as estimate tile. */
	this._goal_estimate_tile = goals[0];
	foreach (tile in goals) {
		if (AIMap.DistanceManhattan(sources[0], tile) < AIMap.DistanceManhattan(sources[0], this._goal_estimate_tile)) {
			this._goal_estimate_tile = tile;
		}
	}

	local nsources = [];
	foreach (node in sources) {
		nsources.push([node, this._GetDominantDirection(node, this._goal_estimate_tile), 0]);
	}

	this._max_path_length = max_length_offset + max_length_multiplier * AIMap.DistanceManhattan(sources[0], this._goal_estimate_tile);

	this._pathfinder.InitializePath(nsources, goals, ignored_tiles);
}

function ShipPF::FindPath(iterations)
{
	local test_mode = AITestMode();
	local ret = this._pathfinder.FindPath(iterations);
	this._running = (ret == false) ? true : false;
	return ret;
}

function ShipPF::BuildPath(path, delay)
{
	while (path != null) {
//		AISign.BuildSign(path.GetTile(), "" + path.GetParams());
		local parameters = path.GetParams();
		if (parameters == ShipPF._LOCK) {
			if (
				!AIMarine.IsLockTile(path.GetTile())
				&&
				AITile.GetSlope(path.GetTile()) == AITile.SLOPE_FLAT
				&&
				AITile.GetSlope(path.GetParent().GetTile()) == AITile.SLOPE_FLAT
			) {
				// Build a lock
				local lock_tile = path.GetTile() - ((path.GetTile() - path.GetParent().GetTile()) / 2);
				//AISign.BuildSign(lock_tile, "Lock");
				//AILog.Info(AIMap.GetTileX(lock_tile) + "," + AIMap.GetTileY(lock_tile));
				if (!AITile.IsBuildable(path.GetTile()) && !AIMarine.IsCanalTile(path.GetTile())) {AITile.DemolishTile(path.GetTile());}
				if (!AITile.IsBuildable(lock_tile)) {AITile.DemolishTile(lock_tile);}
				if (!AITile.IsBuildable(path.GetParent().GetTile()) && !AIMarine.IsCanalTile(path.GetTile())) {AITile.DemolishTile(path.GetParent().GetTile());}
				if (!AIMarine.BuildLock(lock_tile)) {
					AILog.Error("Lock " + AIMap.GetTileX(lock_tile) + "," + AIMap.GetTileY(lock_tile) + " " + AIError.GetLastErrorString());
				} else {
					AILog.Warning("Lock " + AIMap.GetTileX(lock_tile) + "," + AIMap.GetTileY(lock_tile));
					// Slow down build speed
					AIController.Sleep(delay);
				}
			}
		} else if (parameters == ShipPF._BRIDGE) {
			if (!AIBridge.IsBridgeTile(path.GetTile())) {
				local Distance = (path.GetParent() == null) ? 1 : AIMap.DistanceManhattan(path.GetTile(), path.GetParent().GetTile());
				//AISign.BuildSign(path.GetTile(), "Bridge " + (Distance + 1));
				// Build a bridge
				local bridge_list = AIBridgeList_Length(Distance + 1);
				bridge_list.Valuate(AIBridge.GetMaxSpeed);
				bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
				if (!AITile.IsBuildable(path.GetTile())) {AITile.DemolishTile(path.GetTile());}
				if (!AITile.IsBuildable(path.GetParent().GetTile())) {AITile.DemolishTile(path.GetParent().GetTile());}
				if (!AIBridge.BuildBridge(AIVehicle.VT_WATER, bridge_list.Begin(), path.GetTile(), path.GetParent().GetTile())) {
					AILog.Error("Bridge " + AIMap.GetTileX(path.GetTile()) + "," + AIMap.GetTileY(path.GetTile()) + " => " + AIMap.GetTileX(path.GetParent().GetTile()) + "," + AIMap.GetTileY(path.GetParent().GetTile()) + " " + AIError.GetLastErrorString());
				} else {
					AILog.Warning("Bridge " + AIMap.GetTileX(path.GetTile()) + "," + AIMap.GetTileY(path.GetTile()) + " => " + AIMap.GetTileX(path.GetParent().GetTile()) + "," + AIMap.GetTileY(path.GetParent().GetTile()));
					// Slow down build speed
					AIController.Sleep(delay);
				}
			}
		} else {
			if (!AITile.HasTransportType(path.GetTile(), AITile.TRANSPORT_WATER)) {
				if (AITile.GetSlope(path.GetTile()) == AITile.SLOPE_FLAT) {
					//AISign.BuildSign(path.GetTile(), "C");
					if (!AITile.IsBuildable(path.GetTile())) {AITile.DemolishTile(path.GetTile());}
					if (!AIMarine.BuildCanal(path.GetTile())) {
						AILog.Error("Canal " + AIMap.GetTileX(path.GetTile()) + "," + AIMap.GetTileY(path.GetTile()) + " " + AIError.GetLastErrorString());
					} else {
						AILog.Warning("Canal " + AIMap.GetTileX(path.GetTile()) + "," + AIMap.GetTileY(path.GetTile()));
						// Slow down build speed
						AIController.Sleep(delay);
					}
				}
			}
		}
		path = path.GetParent();
	}
	
	return true;
}

function ShipPF::_Cost(self, path, new_tile, new_direction, new_params)
{
	/* path == null means this is the first node of a path, so the cost is 0. */
	if (path == null) return 0;

	local prev_tile = path.GetTile();
	local cost = 0;

	// Lock
	if (new_params == ShipPF._LOCK) {
		cost += 3 * self._cost_tile;
		if (!AIMarine.IsLockTile(new_tile)) {
			cost += 3 * self._cost_lock_per_tile;
//			AILog.Warning("New lock");
		}

	// Bridge
	} else if (new_params == ShipPF._BRIDGE) {
		// If the new tile is a bridge tile, check whether we came from the other
		// end of the bridge or if we just entered the bridge.
		if (AIBridge.IsBridgeTile(new_tile)) {
			if (AIBridge.GetOtherBridgeEnd(new_tile) == prev_tile) {
				cost += (AIMap.DistanceManhattan(new_tile, prev_tile) + 1) * self._cost_tile;
			}
		} else {
			cost += (AIMap.DistanceManhattan(new_tile, prev_tile) + 1) * (self._cost_tile + self._cost_bridge_per_tile);
//			AILog.Warning("New bridge");
		}

	// Canals and open water
	} else {
		cost += self._cost_tile;
		if (!AITile.HasTransportType(new_tile, AITile.TRANSPORT_WATER)) {
			cost += self._cost_canal;
//			AILog.Warning("New canal");
		
			// Detect turns
			if (
				path.GetParent() != null
				&&
				self._GetDirection(path.GetParent().GetTile(), prev_tile) != self._GetDirection(prev_tile, new_tile)
			) {
				cost += self._cost_turn;
			}
		}
	}

	// Demolition costs extra
	if (
		!AITile.HasTransportType(new_tile, AITile.TRANSPORT_WATER)
		&&
		!AITile.IsBuildable(new_tile)
		&&
		!AIMarine.IsCanalTile(new_tile)
		&&
		!AIMarine.IsLockTile(new_tile)
		&&
		!AIBridge.IsBridgeTile(new_tile)
	) {
		cost += self._cost_demolition;
	}

	/* Call all extra cost callbacks. */
	foreach (item in self._cost_callbacks) {
		local extra_cost = item[0](self, path, new_tile, new_direction, new_params, item[1]); 
		if (typeof(extra_cost) != "integer") throw("Cost callback didn't return an integer.");

		cost += extra_cost;
	}

	return path.GetCost() + cost;
}

function ShipPF::_Estimate(self, cur_tile, cur_direction, cur_params, goal_tiles)
{
	/* As estimate we multiply the lowest possible cost for a single tile with
	 * with the minimum number of tiles we need to traverse. */
	return AIMap.DistanceManhattan(cur_tile, self._goal_estimate_tile) * self._cost_tile * self._estimate_multiplier;
}

function ShipPF::_Neighbours(self, path, cur_node)
{
	// _max_cost is the maximum path cost, if we go over it, the path isn't valid.
	if (path.GetCost() >= self._max_cost) return [];

	// _max_path_length is the maximum path length, if we go over it, the path isn't valid.
	if (path.GetLength() + AIMap.DistanceManhattan(cur_node, self._goal_estimate_tile) > self._max_path_length) return [];


	local tiles = [];
	local cur_params = path.GetParams(); 


//	AIController.Sleep(2);


/*	{
		local exec = AIExecMode();
		AISign.BuildSign(cur_node, "" + cur_params);
	}*/
	


	/* Offsets for adjacent tiles */
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),		// Down, up
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];		// Left, right





	/* Check if the current tile is part of an existing bridge. This code is passed 2 times for each end of the bridge. */
	if (
		AIBridge.IsBridgeTile(cur_node)
		&&
		AITile.HasTransportType(cur_node, AITile.TRANSPORT_WATER)
	) {
		local other_end = AIBridge.GetOtherBridgeEnd(cur_node);

		// The other end of the bridge is a neighbour.
//		AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " Existing bridge");
		tiles.push([other_end, self._GetDirection(cur_node, other_end), 0]);

		// Add adjacent tile which is the entry/exit tiles to the bridge.
		local offset = (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		local next_tile = cur_node + offset;
		if (
			self._TileIsValidExitLocation(self, next_tile, offset)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Adjacent tile to an existing bridge");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
		}

		return tiles;
	}





	/* Check if the current tile is part of an existing lock. */
	if (
		AIMarine.IsLockTile(cur_node)
	) {
//		AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " Lock");

		local offset = 0;
		local next_tile = 0;
		if (path.GetParent() != null) {
			offset = cur_node - path.GetParent().GetTile();
		} else {
			foreach (direction in offsets) {
				if (!AIMarine.IsLockTile(cur_node + direction)) continue;
				if (!AIMarine.AreWaterTilesConnected(cur_node, cur_node + direction)) continue;
				offset = direction;
				break;
			}

			if (offset == 0) {
				throw("Unable to detect lock direction");
			}
		}

		next_tile = cur_node + offset;

		if (
			AIMarine.IsLockTile(next_tile)
			&&
			AIMarine.AreWaterTilesConnected(cur_node, next_tile)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Water (lock)");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
		} else if (
			self._TileIsValidExitLocation(self, next_tile, offset)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Clear exit");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
		} else {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " No clear exit");
		}
		
		return tiles;
	}





	/* When the current node has a directional value higher than 15 it means that either a bridge
	 * or lock needs to be build in the direction. */
	if (
		path.GetParent() != null
		&&
		(
			cur_params == ShipPF._BRIDGE
			||
			cur_params == ShipPF._LOCK
		)
	) {
		local other_end = path.GetParent().GetTile();
//		AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " Other end of lock or bridge started at " + AIMap.GetTileX(other_end) + "," + AIMap.GetTileY(other_end));

		local offset = (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		local next_tile = cur_node + offset;
		if (
			self._TileIsValidExitLocation(self, next_tile, offset)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Clear exit");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
		} else {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " No clear exit");
		}

		return tiles;
	}





	/* On non-flat tiles we check if a bridge could be build. */
	local cur_node_slope = AITile.GetSlope(cur_node);
	if (cur_node_slope != AITile.SLOPE_FLAT) {
		local offset = 0;
		if (path.GetParent() != null) {
			offset = cur_node - path.GetParent().GetTile();
		}
		
		local BridgeEndTile = self._CanBuildBridge(self, cur_node, offset);
		if (BridgeEndTile != null) {
//			AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " Can build bridge ending at " + AIMap.GetTileX(BridgeEndTile) + "," + AIMap.GetTileY(BridgeEndTile));
			tiles.push([BridgeEndTile, self._GetDirection(cur_node, BridgeEndTile), ShipPF._BRIDGE]);
	
			return tiles;
		}
	}





	/* Flat tiles could be used for a lock if the next tile have the correct slope and the site is suitable. */
	if (cur_node_slope == AITile.SLOPE_FLAT) {
		local offset = self._GetOffset(path.GetDirection());
		local LockEndTile = self._CanBuildLock(self, cur_node, offset);
		if (LockEndTile != null) {
//			AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " Can build lock ending at " + AIMap.GetTileX(LockEndTile) + "," + AIMap.GetTileY(LockEndTile));
			tiles.push([LockEndTile, self._GetDirection(cur_node, LockEndTile), ShipPF._LOCK]);
		}
	}





//	AILog.Info(AIMap.GetTileX(cur_node) + "," + AIMap.GetTileY(cur_node) + " checking adjacent tiles:");


	/* Check all tiles adjacent to the current tile. */
	foreach (offset in offsets) {
		local next_tile = cur_node + offset;



		// Add tile that have an existing lock in the right direction
		if (
			AIMarine.IsLockTile(next_tile)
			&&
			AIMarine.IsLockTile(next_tile + offset)
			&&
			AIMarine.AreWaterTilesConnected(next_tile, next_tile + offset)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Water (lock)");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
			continue;
		}
		




		// Add tile that already have a canal on it.
		if (
			AIMarine.IsCanalTile(next_tile)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Water (canal)");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
			continue;
		}





		// Add tiles that already have a connection between the current tile and the tile.
		if (
			AIMarine.AreWaterTilesConnected(cur_node, next_tile)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Water");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
			continue;
		}





		// Add tile if it is the entrance of an existing bridge in the correct direction.
		if (
			AIBridge.IsBridgeTile(next_tile)
			&&
			AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER)
		) {
			local other_end = AIBridge.GetOtherBridgeEnd(next_tile);
			if (self._GetDirection(cur_node, next_tile) == self._GetDirection(next_tile, other_end)) {
//				AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Existing Bridge");
				tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
				continue;
			}
		}





		// Add tile if we can build a canal.
		if (
			self._CanBuildCanal(self, next_tile)
		) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Can build canal");
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
			continue;
		}





		// Add tile if it can be used to build a bridge
		local BridgeEndTile = self._CanBuildBridge(self, next_tile, offset);
		if (BridgeEndTile != null) {
//			AILog.Info("   " + AIMap.GetTileX(next_tile) + "," + AIMap.GetTileY(next_tile) + " Can build bridge that end at " + AIMap.GetTileX(BridgeEndTile) + "," + AIMap.GetTileY(BridgeEndTile));
			tiles.push([next_tile, self._GetDirection(cur_node, next_tile), 0]);
		}
	}

//	if (cur_node == AIMap.GetTileIndex(24, 35)) {AILog.Warning("PAUSE!!!!!"); AIController.Sleep(100);}

	return tiles;
}

function ShipPF::_CheckDirection(self, tile, existing_direction, new_direction, tile_params)
{
	return false;
}

function ShipPF::_GetDirection(from, to)
{
	if (from - to >= AIMap.GetMapSizeX()) return 4;		// Up
	if (from - to > 0) return 1;						// Right
	if (from - to <= -AIMap.GetMapSizeX()) return 8;	// Down
	if (from - to < 0) return 2;						// Left
}

function ShipPF::_GetDominantDirection(from, to)
{
	local xDistance = AIMap.GetTileX(from) - AIMap.GetTileX(to);
	local yDistance = AIMap.GetTileY(from) - AIMap.GetTileY(to);
	if (abs(xDistance) >= abs(yDistance)) {
		if (xDistance < 0) return 2;					// Left
		if (xDistance > 0) return 1;					// Right
	} else {
		if (yDistance < 0) return 8;					// Down
		if (yDistance > 0) return 4;					// Up
	}
}

function ShipPF::_GetOffset(direction)
{
	if (direction == 1) return -1;						// Right
	if (direction == 2) return 1;						// Left
	if (direction == 4) return -AIMap.GetMapSizeX();	// Up
	if (direction == 8) return AIMap.GetMapSizeX();		// Down
}

function ShipPF::_TileIsBuildable(self, tile) {
	return (
		AITile.IsBuildable(tile)
		||
		(
			self._allow_demolition
			&&
			AITile.DemolishTile(tile)
		)
	);
}

function ShipPF::_TileIsValidExitLocation(self, tile, offset) {
	return (
		AITile.IsWaterTile(tile)
		||
		self._CanBuildCanal(self, tile)
		||
		self._CanBuildBridge(self, tile, offset)
		||
		self._CanBuildLock(self, tile, offset)
	);
}

function ShipPF::_CanBuildCanal(self, tile) {
	return (
		self._TileIsBuildable(self, tile)
		&&
		AITile.GetSlope(tile) == AITile.SLOPE_FLAT
	);
}

function ShipPF::_CanBuildBridge(self, tile, offset) {
	if (!self._TileIsBuildable(self, tile)) return null;

	local start_slope = AITile.GetSlope(tile);
	local tile_delta = 0;
	if (start_slope == AITile.SLOPE_SE)	{tile_delta = AIMap.GetTileIndex(0, -1);}	// Up
	if (start_slope == AITile.SLOPE_NE)	{tile_delta = AIMap.GetTileIndex(1, 0);}	// Left
	if (start_slope == AITile.SLOPE_NW)	{tile_delta = AIMap.GetTileIndex(0, 1);}	// Down
	if (start_slope == AITile.SLOPE_SW)	{tile_delta = AIMap.GetTileIndex(-1, 0);}	// Right
	if (tile_delta == 0) return null;
	if (tile_delta != offset && offset != 0) return null;

	local end_slope = AITile.GetComplementSlope(start_slope);
	local height = AITile.GetMaxHeight(tile);
	for (local i = 1; i < self._max_bridge_length; i++) {
		local target = tile + (i * tile_delta);
		if (AITile.GetMaxHeight(target) >= height) {
			if (end_slope == AITile.GetSlope(target)) {
				local bridge_list = AIBridgeList_Length(i + 1);
				bridge_list.Valuate(AIBridge.GetPrice, i + 1);
				bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, true);
				if (
					!bridge_list.IsEmpty()
					&&
					AIBridge.BuildBridge(AIVehicle.VT_WATER, bridge_list.Begin(), tile, target)
					&&
					self._TileIsValidExitLocation(self, (target + tile_delta), tile_delta)
				) {
					return target;
				}
			}
			return null;
		}
	}

	return null;
}

function ShipPF::_CanBuildLock(self, tile1, offset) {
	/* Offsets for adjacent tiles */
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),		// Down, up
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];		// Left, right

	local tile2 = tile1 + offset;
	local tile3 = tile1 + (2 * offset);

	if (
		// Tile 1 & 3 - Must be a water tiles, canal tiles or ready for a canals to be build
		(
			AITile.IsWaterTile(tile1)
			||
			self._CanBuildCanal(self, tile1)
		)
		&&
		(
			AITile.IsWaterTile(tile3)
			||
			self._CanBuildCanal(self, tile3)
		)
		&&
		// Tile 2 - Must be buildable and sloped in correct direction
		(
			self._TileIsBuildable(self, tile2)
			&&
			(
				(
					(
						AITile.GetSlope(tile2) == AITile.SLOPE_NW
						||
						AITile.GetSlope(tile2) == AITile.SLOPE_SE
					)
					&&
					(
						tile1 == (tile2 + offsets[0])
						||
						tile1 == (tile2 + offsets[1])
					)
				)
				||
				(
					(
						AITile.GetSlope(tile2) == AITile.SLOPE_SW
						||
						AITile.GetSlope(tile2) == AITile.SLOPE_NE
					)
					&&
					(
						tile1 == (tile2 + offsets[2])
						||
						tile1 == (tile2 + offsets[3])
					)
				)
			)
		)
		&&
		self._TileIsValidExitLocation(self, (tile3 + offset), offset)
	) {
		return tile3;
	} else {
		return null;
	}
}
