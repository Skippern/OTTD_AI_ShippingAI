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

class ShippingAI extends AIInfo {
	function GetAuthor()        { return "Aun Johnsen"; }
	function GetName()          { return "ShippingAI"; }
	function GetShortName()     { return "SHAI"; }
	function GetDescription()   { return "An AI shipping company"; }
	function GetVersion()       { return 1; }
	function MinVersionToLoad() { return 1; }
	function GetDate()          { return "2013-12-04"; }
	function CreateInstance()   { return "ShippingAI"; }
	function GetAPIVersion()    { return "1.3"; }
	function GetSettings() {
		AddSetting({name = "always_autorenew", 
			description = "Always use autoreplace regardless of the breakdown setting", 
			easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, 
			flags = AICONFIG_BOOLEAN});
		AddSetting({name = "hq_in_town", 
			description = "Always build company headquarter in town", 
			easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, 
			flags = AICONFIG_BOOLEAN});
		AddSetting({name = "maintain_network", 
			description = "Maintain network of shipping routes", 
			easy_value = 0, medium_value = 0, hard_value = 1, custom_value = 0, 
			flags = AICONFIG_BOOLEAN});
	}
};

RegisterAI(ShippingAI());
