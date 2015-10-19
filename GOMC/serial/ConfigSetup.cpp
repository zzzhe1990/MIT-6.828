#include <map> //for function handle storage.
#include <string> //for var names, etc.

#include "ConfigSetup.h"

const std::string config_setup::PRNGKind::KIND_RANDOM = "RANDOM", 
   config_setup::PRNGKind::KIND_SEED = "INTSEED", 
   config_setup::PRNGKind::KIND_RESTART = "RESTART",
   config_setup::FFKind::FF_CHARMM = "CHARMM",
   config_setup::FFKind::FF_EXOTIC = "EXOTIC",
   config_setup::FFKind::FF_MARTINI = "MARTINI",
   config_setup::FFValues::VDW = "VDW",
   config_setup::FFValues::VDW_SHIFT = "VDW_SHIFT",
   config_setup::FFValues::VDW_SWITCH = "VDW_SWITCH";

const char ConfigSetup::defaultConfigFileName[] = "in.dat";
const char ConfigSetup::configFileAlias[] = "GO-MC Configuration File";

const uint config_setup::FFValues::VDW_STD_KIND = 0,
   config_setup::FFValues::VDW_SHIFT_KIND = 1,
   config_setup::FFValues::VDW_SWITCH_KIND = 2;

//Map variable names to functions
std::map<std::string, ReadableBase *> ConfigSetup::SetReadFunctions(void)
{
   std::map<std::string, ReadableBase *> funct;
   funct["InState"] = &in.restart;
   funct["PRNG"] = &in.prng;
   funct["FFKind"] = &in.ffKind;
   funct["InParam"] = &in.files.param;
   funct["InPDB"] = &in.files.pdb;
   funct["InPSF"] = &in.files.psf;
   funct["InSeed"] = &in.files.seed;
   funct["Potential"] = &sys.ff;
   funct["Temperature"] = &sys.T;
   funct["Steps"] = &sys.step;
   funct["Percent"] = &sys.moves;
   funct["BoxDim"] = &sys.volume;
   funct["OutNameUnique"] = &out.statistics.settings.uniqueStr;
   funct["OutHistSettings"] = &out.state.files.hist;
   funct["OutPDB"] = &out.state.files.pdb;
   funct["OutPSF"] = &out.state.files.psf;
   funct["OutSeed"] = &out.state.files.seed;
   funct["OutEnergy"] = &out.statistics.vars.energy;
   funct["OutPressure"] = &out.statistics.vars.pressure;
#if ENSEMBLE == GCMC
   funct["ChemPot"] = &sys.chemPot;
#elif ENSEMBLE == GEMC
   funct["GEMC"] = &sys.gemc;
#endif
#ifdef VARIABLE_VOLUME
   funct["OutVolume"] = &out.statistics.vars.volume;
#endif
#ifdef VARIABLE_PARTICLE_NUMBER
   funct["CBMCNonbonded"] = &sys.cbmcTrials.nonbonded;
   funct["CBMCBonded"] = &sys.cbmcTrials.bonded;
   funct["OutMolNum"] = &out.statistics.vars.molNum;
   funct["OutAcceptAngles"] = &out.statistics.vars.acceptAngles;
#endif
#ifdef VARIABLE_DENSITY
   funct["OutDensity"] = &out.statistics.vars.density;
#endif
   return funct;
}

//Map step dependent variable names to functions
std::map<std::string, ReadableStepDependentBase *> 
   ConfigSetup::SetStepDependentReadFunctions(void)
{
   std::map<std::string, ReadableStepDependentBase *> funct;
   funct["OutConsole"] = &out.console;
   funct["OutState"] = &out.state.settings;
   funct["OutRestart"] = &out.restart.settings;
   funct["OutBlockAverage"] = &out.statistics.settings.block;
   funct["OutFluctuation"] = &out.statistics.settings.fluct;
   funct["OutHistogram"] = &out.statistics.settings.hist;
   return funct;
}

void ConfigSetup::Init(char const*const fileName)
{
   using namespace std;
   map<string, ReadableBase *>::const_iterator basic;
   map<string, ReadableStepDependentBase *>::const_iterator stepDependent;
   string varName="", commentChar = "#";
   Reader config((fileName==NULL?defaultConfigFileName:fileName), 
		 configFileAlias, false, NULL, true, &commentChar);
   config.open();
   while (config.Read(varName))
   {
      basic = readVar.find(varName);
      if ( basic != readVar.end() )
	 basic->second->Read(config);
      else
      {
	 stepDependent = readStepDependVar.find(varName);
	 if (stepDependent != readStepDependVar.end())
	    stepDependent->second->Read(config, sys.step.total, varName);
	 else
	 {
	    cerr << "WARNING: Unknown variable found in GOMC configuration "
		 << "file:" << endl << varName << endl << endl;
	    config.SkipLine();
	 }
      }
   }
   config.close();
}
