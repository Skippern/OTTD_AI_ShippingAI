/*
 * This file is part of ShippingAI.
 *
 * ShippingAI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * ShippingAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ShippingAI.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2013 Aun Johnsen
 */

/** @file main.nut Implementation of ShippingAI, containing the main loop. */

import("util.MinchinWeb", "MetaLib", 6);
	PathfinderShip <- MetaLib.ShipPathfinder;
	Marine <- MetaLib.Marine;


/**
 * The main class of ShippingAI.
 */
class ShippingAI extends AIController
{
/* private: */

/* public: */
	_yard_list = null;
    _save_data = { };
//	_save_version = null;

	constructor()
	{
		::main_instance <- this;
		/* Introduce a constant for sorting AILists here, it may be in the api later.
		 * This needs to be done here, before any instance of it is made. */
		 
		 this._yard_list = AIDepotList(AITile.TRANSPORT_WATER);
//		 this._save_data = null;
//		 this._save_version = null;
		 
		/* Most of the initialization is done in Init, but we set some variables 
		 * here so we can save them without checking for null */
//		this._pending_events = [];
//		this.sell_stations = [];
	}
	
	/**
	 * Initialize all 'global' variables. Since there is a limit on the time the constructor
	 * can take we don't do this in the constructor
	 */
	function Init()
	{
//		this._passenger_cargo_id = Util_General.GetPassengerCargoID();
	}
	
	/**
	 * Save all data we need to be able to resume later.
	 * @return A table containing all data that needs to be saved
	 * @note This is called by OpenTTD, no need to call from within the AI
	 */
	function Save();
	
	/**
	 * Store the savegame data we get
	 * @param version The version of this AI that was used to save the game
	 * @param data The data that was stored by Save()
	 * @note This is called by OpenTTD, no need to call from within the AI
	 */
//	function Load(version, data);
	
	/**
	 * Use the savegame data to reconstruct as much state as possible
	 */
//	function CallLoad();


	/**
	 * The main loop
	 * @note This is called by OpenTTD, no need to call from within the AI
	 */
	function Start();
	
/* private: */ 
};


/*
 * Saving important values here
 */
function ShippingAI::Save()
{
    AILog.Info(TimeStamp() + "[Board] Saving Books and Records");
    this._yard_list = AIDepotList(AITile.TRANSPORT_WATER);
    

    AILog.Info(TimeStamp() + "[Board] Books and Records Saved");

    return this._save_data;
}



/*
 * Build company headquarter
 */
function ShippingAI::BuildHQ(town)
{
	AILog.Info(TimeStamp() + "[Constructrion] Building Company HQ in "+ AITown.GetName(town));
	
	local Walker = MetaLib.SpiralWalker();
	Walker.Start(AITown.GetLocation(town));
	local HQBuilt = false;
	while (HQBuilt == false) {
		HQBuilt = AICompany.BuildCompanyHQ(Walker.Walk());
	}


	if (AICompany.GetLoanAmount() > 0 ) {
		AILog.Info(TimeStamp() + "[Finance] Preparing to repay loan");
		local loan = AICompany.GetLoanAmount();
		local interval = AICompany.GetLoanInterval();
		local bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
		while (1) {
			loan -= interval;
			AICompany.SetLoanAmount(loan);
			bankBalance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
			if (bankBalance < interval) break;
		}
		if (AICompany.GetLoanAmount() == 0) {
			AILog.Info(TimeStamp() + "[Finance] Loan paid completely");
			return; // Loan paid down
		}
	}
}


function ShippingAI::TimeStamp() {
	local now = AIDate.GetCurrentDate();
	local year = AIDate.GetYear(now);
	local month = AIDate.GetMonth(now);
	local day = AIDate.GetDayOfMonth(now);
	local aMonth = "";
	local aDay = "";
	if (month < 10) aMonth = "0";
	if (day < 10) aDay = "0";
	return "[" + year + "-" + aMonth + month + "-" + aDay + day + "] ";
}

function ShippingAI::SetCompanyName()
{
	AILog.Info(TimeStamp() + "[Board] Trying to set company name");
	/*
	 * Getting the President name, to be used in Company Name
	 */
	local presName = AICompany.GetPresidentName(AICompany.COMPANY_SELF);
	/* Company name prefixes */
	local prefixes = ["Tsakos", "Rovde", "Nordenfieldske", "Knutsen", "Solstad", "Farstad", 
			"Olympic", "Poseidon", "Island", "Sundenfieldske", "Bergersen", "Navios", "Stena", 
			"Saga", "Mowinkel", "Maersk", "Utkilen", "Sealand", "Hapag-Lloyd", "Lloyd", "Peninsula", 
			"Navion", "Frontline", "Jeppesen", "Westfal-Larsen", "Wilson", "Eidesvik", "East India", 
			"Orient", "Father", "Occident", "West India", "Far East", "Seaway", "Fred Olsen", 
			"Red Band", presName, presName, "Neptune", "Poseidon", "Greate Lakes", "Siem", "Havila",
			"Holland America", "Torm", "East Aisatic", "Hamburg Süd", "Atlas", "Costamare", "Excel",
			"Eimskip", "Belship", "Borgstad", "Det Stavangerske", "Eidsiva", "Eitzen", "Golar", "Grieg",
			"Odfjell", "Stolt-Nielsen", "Wallenius Wilhelmsen", "Wilhelm Wilhelmsen", "Polsteam",
			"Portline", "Histria", "Shakalin", "Sovcomflot", "African and Eastern", "African", "Bibby",
			"Clan", "Court", "Guinea Gulf", "Gulf", "Loch", "London and Overseas", "Pacific", "Palm",
			"Anglo-Eastern", "Mercator", "Bumi Laut", "Mitsui", "Nippon Yusen Kaisha", "Mitsubishi"
			"Kawasaki Kisen Kaisha", "Yamashita", "Hanjin", "Hyundai", "Horizon", "Crowley", "Cunard",
			"Anchor", "Crown", "Port", "Union-Castle", "Negros", "Strait", "Reef", "Union", "Gearbulk",
			"Grimaldi", "Overseas", "Zodiac"];
	/* Company name suffixes */
	local suffixes = ["Shipping", "& Sons", "& Co.", "Ltd.", "Global", "International", "& Cia", 
		"Steamship Company", "Maritime", "Worldwide", "Lines", "Inc.", "Motorship Company", 
		"Trading Company", "Tradewinds", "Shipping Company", "Navigation Company", "Freighters" ];
	/* Now let us loop this until we get a unique name */
	while (1) {
		local myname = (prefixes[AIBase.RandRange(prefixes.len())] + " " + 
			suffixes[AIBase.RandRange(suffixes.len())]);
		AICompany.SetName(myname);
		if (AICompany.GetName(AICompany.COMPANY_SELF) == myname) break;
	}
}

function ShippingAI::Start()
{
	AILog.Info(TimeStamp() + "[Startup] Starting ShippingAI");
	/* Check if the names of some settings are valid. Of course this isn't
	 * completely failsafe, as the meaning could be changed but not the name,
	 * but it'll catch some problems */
	
	/* Call our real constructor here to prevent 'is taking too long to load' error */
	
	
	local start_tick = AIController.GetTick();

    /* If we are starting from a save-game, skip the parts of company startup, as we already
     * have an elected board president, company name, and headquarter.
     */
	
	if (AICompany.GetName(AICompany.COMPANY_SELF).find("ShippingAI") == null) {
		this.SetCompanyName();
		AILog.Info(TimeStamp() + "[Board] " + AICompany.GetName(AICompany.COMPANY_SELF) + 
			" has just started!");
		AILog.Info(TimeStamp() + "[Board] " + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + 
			" is managing the company");
	}
		
	/* Before starting the main loop, sleep a bit to prevent problems with ECS */
	AILog.Info(TimeStamp() + "[Debugging] Now, let us figure out what kind of cargoes we have");
	/* First let us find out what we can transport */
	local cargoList = AICargoList();
	cargoList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	local cargo = cargoList.Begin();
	while (1) {
		if (cargoList.IsEnd()) break;
		local str = AICargo.GetCargoLabel(cargo) + " (" + cargo +") has following cargo classes: [";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)) str += "CC_PASSENGERS, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_MAIL)) str += "CC_MAIL, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_EXPRESS)) str += "CC_EXPRESS, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_ARMOURED)) str += "CC_ARMOURED, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_BULK)) str += "CC_BULK, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_PIECE_GOODS)) str += "CC_PIECE_GOODS, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_LIQUID)) str += "CC_LIQUID, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_REFRIGERATED)) str += "CC_REFRIGERATED, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_HAZARDOUS)) str += "CC_HAZARDOUS, ";
		if (AICargo.HasCargoClass(cargo, AICargo.CC_COVERED)) str += "CC_COVERED, ";
		str += "]";
		AILog.Info(TimeStamp() + "[Debugging] " + str);
		cargo = cargoList.Next();
	}
	/*
	local bulkList = AICargoList();
	bulkList.Valuate(function(cargo_id, cargo_class) { 
		if(AICargo.HasCargoClass(cargo_id, cargo_class)) return 1; return 0; },  AICargo.CC_BULK);
	bulkList.KeepValue(1);
	*/

	local industryTypeList = AIIndustryTypeList();
	industryTypeList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	local ind = industryTypeList.Begin();
	while (1) {
		if (industryTypeList.IsEnd()) break;
		local acceptString = "[";
		local i = 0;
		if (AIIndustryType.IsRawIndustry(ind) ) acceptString += "RAW";
		else {
			local acceptList = AIIndustryType.GetAcceptedCargo(ind);
			i = acceptList.Begin();
			acceptString += AICargo.GetCargoLabel(i);
			i = acceptList.Next();
			if (!acceptList.IsEnd()) acceptString += ","+AICargo.GetCargoLabel(i);
			i = acceptList.Next();
			if (!acceptList.IsEnd()) acceptString += ","+AICargo.GetCargoLabel(i);
			i = acceptList.Next();
			if (!acceptList.IsEnd()) acceptString += ","+AICargo.GetCargoLabel(i);
		}
		acceptString += "]";
		local produceString = "[";
		local produceList = AIIndustryType.GetProducedCargo(ind);
		i = produceList.Begin();
		if (produceList.IsEnd()) produceString += "NONE";
		else produceString += AICargo.GetCargoLabel(i);
		i = produceList.Next();
		if (!produceList.IsEnd()) produceString += ","+AICargo.GetCargoLabel(i);
		i = produceList.Next();
		if (!produceList.IsEnd()) produceString += ","+AICargo.GetCargoLabel(i);
		i = produceList.Next();
		if (!produceList.IsEnd()) produceString += ","+AICargo.GetCargoLabel(i);
		produceString += "]";
		AILog.Info(TimeStamp() + "[Debugging] " + ind + ": " + AIIndustryType.GetName(ind) + " " + 
			acceptString + "->" + produceString);
		ind = industryTypeList.Next();
	}

	local engineList = AIEngineList(AIVehicle.VT_WATER);
	engineList.Valuate(Marine.RateShips, 20, 0);
//	engineList.KeepValue(VT_WATER);
	engineList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	local i = 0;
	local test = null;
	for (test = engineList.Begin(); !engineList.IsEnd(); test = engineList.Next() ) {
		local engineName = AIEngine.GetName(test);
		local engineCargo = AICargo.GetCargoLabel(AIEngine.GetCargoType(test));
		local engineCapacity = AIEngine.GetCapacity(test);
		i++;
		AILog.Info(TimeStamp() + "[Debugging] #" + i + ": " + engineName + " takes " + 
			engineCapacity + " of " + engineCargo);
	}
	/* End of loading */
	AILog.Info(TimeStamp() + "[Startup] Loading done!");

	this.FinancialDepartment();

	AIController.Sleep(max(1, 360 - (AIController.GetTick() - start_tick)));
	this.FinancialDepartment(); /* Check finances before starting up */
	/* Now is time to start doing something */

	this.CharteringDepartment();
	local stations = AIStationList(AIStation.STATION_DOCK);
	local test = stations.Begin();
	this.BuildHQ(AIStation.GetNearestTown(test));

	
	local sleeper = 300;
	while (1) {
		this.FinancialDepartment();
		this.TechnicalDepartment();
		this.CharteringDepartment();
		this.Sleep(sleeper);
	}

}

/*
 * FinanceDepartment takes care of book-keeping, make sure we don't run out of cash, and 
 * pay down on loan as long as we have money
 */
function ShippingAI::FinancialDepartment()
{
	if (AICompany.GetLoanAmount() > 0 && 
		AICompany.GetLoanInterval() < AICompany.GetBankBalance(AICompany.COMPANY_SELF)) {
			AICompany.SetLoanAmount( AICompany.GetLoanAmount() - AICompany.GetLoanInterval() );
			AILog.Info(TimeStamp() + "[Finance] Paid off a chunk on the loan");
	}
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 1) {
		if (AICompany.GetMaxLoanAmount() > AICompany.GetLoanAmount()) {
			AICompany.SetLoanAmount( AICompany.GetLoanAmount() + AICompany.GetLoanInterval() );
			AILog.Info(TimeStamp() + "[Finance] Running low in cash, increasing loan");
		} else {
			AILog.Error(TimeStamp() + "[Finance] We are bankrupt soon if we don't start to make money!");
		}			
	}
	AILog.Info(TimeStamp() + "[Finance] Books and Accounts balanced");
}

/*
 * Make sure we have enough money for the planned action
 */
function ShippingAI::Budgeting(needed)
{
	AILog.Info(TimeStamp() + "[Board] Finance Department contacted, reserving " + needed + 
		" for purpose");
	local bank = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local loan = AICompany.GetLoanAmount();
	local maxLoan = AICompany.GetMaxLoanAmount();
	
	if (bank > needed) return; // We have enough money
	local toLoan = needed - bank;
	if ( (toLoan + loan) > maxLoan) { // We cant make it
		AICompany.SetLoanAmount(maxLoan); // but are trying anyway
		AILog.Info(TimeStamp() + "[Chartering] Increasing loan to MAX in order to try to achieve " +
			"our goal");
		return;
	}
}

/*
 * Take care of maintenance of vessels, ordering new vessels, and selling vessels not needed anymore
 */
function ShippingAI::TechnicalDepartment()
{
	AILog.Info(TimeStamp() + "[Technical] Fleet maintained");

}
/*
 * Surveying new routes
 */
function ShippingAI::CharteringDepartment()
{
	local dockList = AIStationList(AIStation.STATION_DOCK);
	/* If this dockList is empty, try building a route without concern about money (probably 
	 * just started the company) */
	if (dockList.Count() > 0) {
		AILog.Info(TimeStamp() + "[Chartering] Since we have some docks, checking money balance");
		/* We will not build a lot of docks, we need to make money as well */
	}
	/* What cargo do we want to transport? */
	local cargo = -1;
	local subsidyList = AISubsidyList();
	subsidyList.Valuate(function(idx) { if (AISubsidy.IsAwarded(idx)) return 0; return 1; } );
	subsidyList.KeepValue(1);
	/* If we didn't find automatically, lets randomly select */
	local cargoList = AICargoList();
	while (!AICargo.IsValidCargo(cargo) ) {
		cargoList.Valuate(AIBase.RandItem);
		cargo = cargoList.Begin();
	}
	
	/* For debugging, lets just override the check and dictate cargo */
//	cargo = 0; // PASS
//	cargo = 1; // COAL
//	cargo = 2; // MAIL
//	cargo = 3; // OIL_
//	cargo = 4; // LVST
//	cargo = 5; // GOOD
//	cargo = 6; // GRAI
//	cargo = 7; // WOOD
//	cargo = 8; // IORE
//	cargo = 9; // WATR
//	cargo = 11; // FOOD
//	cargo = 12; // STEL
//	cargo = 13; // CORE
//	cargo = 14; // FRUT
//	cargo = 15; // DIAM
//	cargo = 16; // PAPR
//	cargo = 17; // GOLD
//	cargo = 18; // RUBR

	subsidyList.Valuate(AISubsidy.GetCargoType);
	subsidyList.KeepValue(cargo);
	
	if (subsidyList && subsidyList.Count() > 0) {
		AILog.Info(TimeStamp() + "[Chartering] Subsidies exists for desired cargo: " + 
			AICargo.GetCargoLabel(cargo));
		/* Let us build subsidy route */
		local from = null;
		local to = null;
		local set = false;
		local test = subsidyList.Begin();
		while (!set) {
			if (AISubsidy.GetSourceType(test) == AISubsidy.SPT_TOWN) {
				from = AITown.GetLocation(AISubsidy.GetSourceIndex(test));
			} else {
				from = AIIndustry.GetLocation(AISubsidy.GetSourceIndex(test));
			}
			if (AISubsidy.GetDestinationType(test) == AISubsidy.SPT_TOWN) {
				to = AITown.GetLocation(AISubsidy.GetDestinationIndex(test));
			} else {
				to = AIIndustry.GetLocation(AISubsidy.GetDestinationIndex(test));
			}
			if (AIMap.IsValidTile(from) && AIMap.IsValidTile(to)) set = true;
		}
		local dock_from = this.BuildDock(from, cargo);
		local dock_to = this.BuildDock(to, cargo);
		local path = this.SurveyRoute(from, to);
		
		AILog.Info(TimeStamp() + "[Chartering] Done contracting subsidy route");
		return;
	} else AILog.Info(TimeStamp() + "[Chartering] No subsidies available for cargo: " + 
		AICargo.GetCargoLabel(cargo));
	
	local townList = AITownList();
	local producingList = AIIndustryList_CargoProducing(cargo);
	local acceptingList = AIIndustryList_CargoAccepting(cargo);
	if (AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS) || 
		AICargo.HasCargoClass(cargo, AICargo.CC_MAIL) ) {
			/* Passengers and Mail are sent from town to town */
			/* I know Oil Platforms and Fishing Grounds (in FIRS?) accepts passengers, but we 
			 * start such routes only from subsidies for now */
	} else if (AICargo.GetCargoLabel(cargo) == "GOOD" || AICargo.GetCargoLabel(cargo) == "FOOD") {
		/* These cargoes are transported from industry to town, if the town is of sufficient 
		 * size, but might also go to industry
		 * Check for both.
		 */
	} else {
		/* This is the easy part, industry to industry */
		producingList.Valuate(AIIndustry.GetLastMonthTransportedPercentage, cargo);
		producingList.KeepBelowValue(60); 
			// to avoid too stiff competition, keep only industries with low transport rate
            // This value should be configurable via settings
		producingList.Valuate(AIIndustry.GetLastMonthProduction, cargo);
		producingList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		local noDock = true;
		local dock_from = null;
		local dock_to = null;
		local producer = producingList.Begin();
		while (noDock) {
			local tileList = Marine.GetPossibleDockTiles(producer);
			if (tileList.len() > 0) {
				/* We should try to connect this one */
				dock_from = this.BuildDock(AIIndustry.GetLocation(producer), cargo);
				if (dock_from != null) noDock = false;
			}
			if (producingList.IsEnd()) {
				AILog.Warning(TimeStamp() + "[Chartering] We where not able to find a " +
					"suitable producer of cargo: " + AICargo.GetCargoLabel(cargo));
				return;
			}
			producer = producingList.Next();
		}
		acceptingList.Valuate(AIIndustry.GetDistanceManhattanToTile, AIIndustry.GetLocation(producer));
		acceptingList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
		local accepter = acceptingList.Begin();
		noDock = true;
		while (noDock) {
			local tileList = Marine.GetPossibleDockTiles(accepter);
			if (tileList.len() > 0) {
				/* We should try to connect this one */
				dock_to = this.BuildDock(AIIndustry.GetLocation(accepter), cargo);
				if (dock_to != null) noDock = false;			
			}
			if (acceptingList.IsEnd()) {
				AILog.Warning(TimeStamp() + "[Chartering] We where not able to find a " +
					"suitable destination for cargo: " + AICargo.GetCargoLabel(cargo));
				return;
			}
			accepter = acceptingList.Next();
		}
//		if (AIMarine.IsDockTile(dock_from) && AIMarine.IsDockTile(dock_to)) {
			AILog.Info(TimeStamp() + "[Chartering] Ready to make route");
			local path = this.SurveyRoute(dock_from, dock_to);
//		}
//		else AILog.Error(TimeStamp() + "[Chartering] Some error occured! No route made");
	}
	
	AILog.Info(TimeStamp() + "[Chartering] Done");
}

/*
 * Checks if there already are docks we can use close to  the industry, if not, try to build one
 */
function ShippingAI::BuildDock(near, cargo)
{
	if (AITile.IsStationTile(near) && 
		(AITile.GetCargoAcceptance(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 7 || 
		AITile.GetCargoProduction(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 0)) {
				return AIStation.GetStationID(near); // Already exist a station on near
	}
	if (AIIndustry.HasDock(AIIndustry.GetIndustryID(near)) && 
		(AITile.GetCargoAcceptance(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 7 || 
		AITile.GetCargoProduction(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 0)) {
				return AIStation.GetStationID(AIIndustry.GetDockLocation(AIIndustry.GetIndustryID(near)));
					// This industry have dock
	}
	local dockType = 0; // not defined
	local industry = null;
	local town = null;
	local dock = null;
	/* Is near a valid industry or town tile? */
	if (AIIndustry.IsValidIndustry(AIIndustry.GetIndustryID(near))) {
		dockType = 1; // Industrial
		industry = AIIndustry.GetIndustryID(near);
		AILog.Info(TimeStamp() + "[Construction] Trying to build dock near industry: " + 
			AIIndustry.GetName(industry));
		if (AIIndustry.HasDock(industry)) {
			dockType = 2; // HasDock true, i.e. Oil Rig
			local tile = AIIndustry.GetDockLocation(industry);
			AILog.Info(TimeStamp() + "[Construction] " + AIIndustry.GetName(industry) + 
				" already have a dock, using it for our purpose");
			return AIStation.GetStationID(tile);
		}
	} else {
		/* The tile is not industry, let see if it is town */
		if (AITile.IsWithinTownInfluence(near, AITile.GetClosestTown(near))) {
			dockType = 3; // town dock
			town = AITile.GetClosestTown(near);
			AILog.Info(TimeStamp() + "[Construction] Trying to build dock near town: " + 
				AITown.GetName(town));
		}
	}
	/* First find out if we already have a dock servicing the industry */
	if (industry) {
		local checkList = Marine.GetPossibleDockTiles(industry);
		local i = 0;
		for (i = 0; i < checkList.len(); i++) {
			if (AIMarine.IsDockTile(checkList[i]) && 
				AIStation.IsValidStation(AIStation.GetStationID(checkList[i])) &&
				(AITile.GetCargoAcceptance(near, cargo, 1, 1, 
					AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 7 || 
				AITile.GetCargoProduction(near, cargo, 1, 1, 
					AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 0)) {
						return AIStation.GetStationID(checkList[i]); // Already serviced by station
			}
		}
	} else if (town) {
		local Walker = MetaLib.SpiralWalker();
		Walker.Start(near);
		local check = false;
		while (!check) {
			check = AIMarine.IsDockTile(Walker.Walk());
			local tile = Walker.GetTile();
			local stationID = AIStation.GetStationID(tile)
			if (check && AIStation.IsWithinTownInfluence(stationID, town) &&
				(AITile.GetCargoAcceptance(near, cargo, 1, 1, 
						AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 7 || 
					AITile.GetCargoProduction(near, cargo, 1, 1, 
						AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) > 0)) {
                            AILog.Info(TimeStamp() + "[Construction] We have found a dock at " +AIStation.GetName(stationID));
							return stationID; // lets use this dock
	 		}
			if (Walker.GetStep() > 100) check = true; 
				// if we havnt found a suitable dock yet, it is probably too far away (or non existing)
		}
	} 
	/* No docks, let us build a new one */
	this.Budgeting(1000);
	local Walker = MetaLib.SpiralWalker();
	Walker.Start(near);
	local tile = null;
	local built = false;
	while (!built) {
		tile = Walker.Walk();
		built = AIMarine.BuildDock(tile, AIStation.STATION_NEW);
	}
//	AILog.Info(TimeStamp() + "[Construction] Completed checks for dock location");
	if (!built) return; // We couldnt build the dock
//	AILog.Info(TimeStamp() + "[Construction] Dock built");
	local dockID = null;
//	if (AIStation.IsValidStation(AIStation.GetStationID(tile))) {
		dockID = AIStation.GetStationID(tile);
//	}
	if (dockID == null) {
		AILog.Error(TimeStamp() + "[Construction] ERROR: Dock have no ID");
		return;
	}
	AILog.Info(TimeStamp() + "[Debugging] AITile.GetCargoAcceptance = " + 
		AITile.GetCargoAcceptance(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) + " AITile.GetCargoProduction = " +
		AITile.GetCargoProduction(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) + " for cargo " + 
			AICargo.GetCargoLabel(cargo));
	if (AITile.GetCargoAcceptance(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) < 8 && 
		AITile.GetCargoProduction(near, cargo, 1, 1, 
			AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) == 0) {
				AILog.Warning(TimeStamp() + "[Construction] Dock does not accept or produce cargo: " + 
					AICargo.GetCargoLabel(cargo));
				local removed = AIMarine.RemoveDock(AIStation.GetLocation(dockID));
				if (removed) AILog.Info(TimeStamp() + "[Construction] Dock abandoned");
				return;
	}
	/* Before we leave, lets try getting an original name on the station */
	local dockName = null;
	switch (dockType) {
		case 1:
			/* Producing or Accepting */
			if (AIIndustry.IsCargoAccepted(industry, cargo) == AIIndustry.CAS_NOT_ACCEPTED) { 
				// Producing
				dockName = " " + AICargo.GetCargoLabel(cargo) + " Docks";
			} else { // Accepting
				if (AICargo.HasCargoClass(cargo, AICargo.CC_BULK)) {
					dockName = " Bulk Terminal";
				} else if (AICargo.HasCargoClass(cargo, AICargo.CC_LIQUID)) {
					dockName = " Tank Terminal";
				} else if (AICargo.HasCargoClass(cargo, AICargo.CC_HAZARDOUS)) {
					dockName = " Dangerous Goods Terminal";
				} else {
					dockName = " " + AIIndustryType.GetName(AIIndustry.GetIndustryType(industry)) + 
						" Terminal";
				}
			}
			break;
		case 2:
			/* We are not changing name of Oil Rigs, etc */
			break;
		case 3:
			if (AICargo.GetCargoLabel(cargo) == "GOOD") {
				if (AIDate.GetYear(AIDate.GetCurrentDate()) > 1979) {
					dockName = " Container Terminal";
				} else {
					dockName = " Goods Terminal";
				}
			} else if (AITown.IsCity(town)) {
				dockName = " City Terminal";
			} else {
				dockName = " Terminal";
			}
			break;
		default:
			/* Do nothing, keep the given name */
	}
	if (dockName) {
		local i = 0;
		local myDockName = AITown.GetName(AITile.GetClosestTown(near)) + dockName;
		local extension = [ "North", "South", "East", "West", "Central", "Riverside", "Beach", 
			"Seafront", "Lakeside", "Main", " Hub" ];
		while (!AIBaseStation.SetName(dockID, myDockName)) {
			i++;
			myDockName = AITown.GetName(AITile.GetClosestTown(near)) + " " + 
				extension[AIBase.RandRange(extension.len())] + dockName;
			
			if (i > 20) {
				i = 0;
				while (!AIBaseStation.SetName(dockID, myDockName)) {
					i++;
					myDockName = AITown.GetName(AITile.GetClosestTown(near)) + dockName + " #" + i;
					if (i > 10) return dockID;
				}
				return dockID;
			}
		}
	}
	return dockID;
}

/*
 * Surveys the route between two docks and connects them
 */
function ShippingAI::SurveyRoute(from_dock, to_dock)
{
	local pathfinder = PathfinderShip();
	local from_tiles = [ from_dock ];
	local to_tiles = [ to_dock ];
	from_tiles.push(Marine.GetDockFrontTiles(from_dock));
	to_tiles.push(Marine.GetDockFrontTiles(to_dock));
	pathfinder.InitializePath(from_tiles, to_tiles);
	
	local path = pathfinder.FindPath(1);
	
	if (!path) {
		AILog.Error(TimeStamp() + "[Survey] ERROR: Path impossible");
		return;
	}
	
	return path;
}