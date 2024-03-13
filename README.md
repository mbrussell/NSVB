# NSVB
<img src="https://www.fs.usda.gov/research/sites/default/files/styles/large/public/2023-09/wo-fia_tree_model_photos.png?itok=W6gO9iLy" align="left" alt="*USDA Forest Service*">

Files and R code to predict tree volume, biomass, and carbon using the US' [National Scale Volume Biomass (NSVB) models](https://www.fs.usda.gov/research/programs/fia/nsvb).

R code uses the approach presented in [Westfall et al. 2023](https://www.fs.usda.gov/research/treesearch/66998) to predict a suite of individual tree attributes depicting the volume, biomass, and carbon stored in trees.  The following variables are a crosswalk between what's presented in the Westfall et al. 2023 examples and the associated variables recorded in the [Forest Inventory and Analysis database (FIADB)](https://www.fs.usda.gov/research/programs/fia):

| Westfall abbr      | FIADB abbr | Definition      | Units |
| ----------- | ----------- | ----------- | ----------- |
| $h_{m}$	| - |	Merchantable height to a 4.0 inch top      | feet       |
| $R_{1}$	| - |		Proportion of volume to 1 foot (i.e., stump)      | -       |
| $R_{m}$	| -	 |	Proportion of volume to the merchantable height (i.e., 4.0 inches)      | -       |
| $h_{s}$ |	-	| Merchantable height to sawlog top (7.0 inches for softwoods; 9.0 inches for hardwoods)      |  feet       |
| $R_{s}$ |	-	| Proportion of volume to sawlog top (7.0 inches for softwoods; 9.0 inches for hardwoods)      | -       |
| $Vtot_{ib}Gross$      | VOLTSGRS       | Gross cubic-foot total-stem wood volume      | cubic feet       |
| $Vtot_{bk}Gross$	| VOLTSGRS_BARK	| Gross cubic-foot total-stem bark volume      | cubic feet       |
| $Vmer_{ib}Gross$ | 	VOLCFGRS	 |	Gross cubic-foot merchantable stem wood volume (inside bark)      | cubic feet       |
| $Vmer_{bk}Gross$ |	VOLCFGRS_BARK	 |	Merchantable stem bark volume      | cubic feet       |
| $Vsaw_{ib}Gross$ |	VOLCSGRS	 |	Gross cubic-foot wood volume in the sawlog portion of a sawtimber tree      | cubic feet       |
| $Vsaw_{bk}Gross$ |	VOLCSGRS_BARK	Gross |	 cubic-foot bark volume in the sawlog portion of a sawtimber tree      | cubic feet       |
| $Vstump_{ib}Gross$ |	VOLCFGRS_STUMP |		Gross cubic-foot stump wood volume (inside bark)      | cubic feet       |
| $Vstump_{bk}Gross$ |	VOLCFGRS_STUMP_BARK	 |	Gross cubic-foot stump bark volume      | cubic feet       |
| $Vtop_{ib}Gross$ |	VOLCFGRS_TOP |		Gross cubic-foot stem-top wood volume, inside bark      | cubic feet       |
| $Vtop_{bk}Gross$ |	VOLCFGRS_TOP_BARK |		Gross cubic-foot stem-top bark volume, outside bark      | cubic feet       |
| $Vtot_{ib}Sound$ |	VOLTSSND |		Sound cubic-foot total-stem wood volume, inside bark      | cubic feet       |
| $Vtot_{bk}Sound$ |	VOLTSSND_BARK	 |	Sound cubic-foot total-stem bark volume      | cubic feet       |
| $Vstump_{ib}Sound$ |	VOLCFSND_STUMP |		Sound cubic-foot stump wood volume      | cubic feet       |
| $Vstump_{bk}Sound$ |	VOLCFSND_STUMP_BARK |		Sound cubic-foot stump bark volume      | cubic feet       |
| $Vmer_{ib}Sound$ |	VOLCFSND |		Sound cubic-foot stem wood volume      | cubic feet       |
| $Vmer_{bk}Sound$ |	VOLCFSND_BARK |		Sound cubic-foot stem bark volume      | cubic feet       |
| $Vtop_{ib}Sound$ |	VOLCFSND_TOP |		Sound cubic-foot stem-top wood volume      | cubic feet       |
| $Vtop_{bk}$ |	VOLCFSND_TOP_BARK |		Sound cubic-foot stem-top bark volume      | cubic feet       |
| $Vsaw_{ib}Sound$ |	VOLCSSND |		Sound cubic-foot wood volume in the sawlog portion of a sawtimber tree      | cubic feet       |
| $Vsaw_{bk}Sound$ |	VOLCSSND_BARK |		Sound cubic-foot bark volume in the sawlog portion of a sawtimber tree      | cubic feet       |
| $AGB_{Predicted}$ |	DRYBIO_AG |		Aboveground dry biomass of wood and bark      | pounds       |
| $Wood_{Harmonized}$ |	DRYBIO_STEM |		Dry biomass of wood in the total stem      | pounds      |
| $Bark_{Harmonized}$ |	DRYBIO_STEM_BARK |		Dry biomass of bark in the total stem | pounds      |
| $Branch_{Harmonized}$ |	DRYBIO_BRANCH |		Dry biomass of branches | pounds      |
| $Wfoliage$ |	DRYBIO_FOLIAGE |		Dry biomass of foliage| pounds      |
| $Wstump_{ib}$ |	DRYBIO_STUMP |		Dry biomass of wood in the stump | pounds      |
| $Wstump_{bk}$ |	DRYBIO_STUMP_BARK |		Dry biomass of bark in the stump| pounds      |
| $Wmer_{ob}$ |	DRYBIO_BOLE |		Dry biomass of wood in the merchantable bole | pounds      |
| $Wmer_{bk}$ |	DRYBIO_BOLE_BARK |		Dry biomass of bark in the merchantable bole | pounds      |
| $Vsaw_{ib}Gross x WDSG_adj x 62.4$ |	DRYBIO_SAWLOG	| Dry biomass of wood in the sawlog portion of a sawtimber tree. | pounds      |
| $Vsaw_{bk}Gross x WDSG_adj x 62.4$ |	DRYBIO_SAWLOG_BARK |	Dry biomass of bark in the sawlog portion of a sawtimber tree | pounds      |
| $C$ |	CARBON_AG	 |	Aboveground carbon of wood and bark | pounds      |
| * estimated using the Component Ratio Method (CRM) |		DRYBIO_BG |		Belowground dry biomass| pounds      |
| * estimated using DRYBIO_BG and CARBON_RATIO_LIVE variable from REF_SPECIES table	 |	CARBON_BG |		Belowground carbon | pounds      |




