#ifndef CONFIGSETUP_H
#define CONFIGSETUP_H

#include <map> //for function handle storage.
#include <iostream> //for cerr, cout;
#include <string> //for var names, etc.

#include "InputAbstracts.h" //For ReadableBase parent class.
#include "../lib/BasicTypes.h" //for uint, ulong
#include "EnsemblePreprocessor.h" //For box total;
#include "Reader.h" //For config reader
#include "FFConst.h" //For # of param file kinds
#include "MersenneTwister.h" //For MTRand::uint32
#include "XYZArray.h" //For box dimensions.
#include "MoveConst.h"
#include "UnitConst.h" //For bar --> mol*K / A3 conversion

#if ENSEMBLE == GCMC
#include <sstream>  //for reading in variable # of chem. pot.
#endif

namespace config_setup
{
   /////////////////////////////////////////////////////////////////////////
   // Reoccurring structures

   //A filename
   struct FileName : ReadableBase
   {
      std::string name;
      void Read(Reader & config){ config.file >> name; }
   };

   //Multiple filenames
   template <uint N>
   struct FileNames : ReadableBase
   {
      std::string name[N];
      void Read(Reader & config)
      { 
	 for (unsigned int i = 0; i < N; i++)
	    config.file >> name[i]; 
      }
   };

   /////////////////////////////////////////////////////////////////////////
   // Input-specific structures

   //Could use "EnableEvent", but restart's enable arguably needs its 
   //own struct as "frequency" is misleading name for step number
   struct RestartSettings : ReadableBase
   {
      bool enable; ulong step;
      bool operator()(void) { return enable; }
      void Read(Reader & config) { config.file >> enable >> step; }
   };

   //Kinds of Mersenne Twister initialization
   struct PRNGKind : ReadableBase
   {
      std::string kind;
      MTRand::uint32 seed;
      bool IsRand(void) const { return str::compare(KIND_RANDOM, kind); }
      bool IsSeed(void) const { return str::compare(KIND_SEED, kind); }
      bool IsRestart(void) const { return str::compare(KIND_RESTART, kind); }
      void Read(Reader & config) 
      { 
         config.file >> kind; 
         if (IsSeed()) 
         { 
            uint tSeed; 
            config.file >> tSeed; 
            seed = (MTRand::uint32)(tSeed); }
      }
      static const std::string KIND_RANDOM, KIND_SEED, KIND_RESTART;
   }; 
   
   struct FFKind : ReadableBase
   {
     bool isCHARMM, isMARTINI;
      void Read(Reader & config) 
      { 
	 std::string kind;
         config.file >> kind; 
	 if(str::compare(FF_CHARMM, kind))
	 {
	   isCHARMM = true;
	   isMARTINI = false;
	   std::cout << "CHARMM Force Field has been selected\n\n";
	 }
	 else if (str::compare(FF_EXOTIC, kind))
	 {
	   isCHARMM = false;
	   isMARTINI = false;
	   std::cout << "EXOTIC Force Field has been selected\n\n";
	 }
	 else if (str::compare(FF_MARTINI, kind))
	 {
	   isMARTINI = true;
	   isCHARMM = true;
	   std::cout << "MARTINI Force Field has been selected\n\n";
	 }
	 else
	 {
	   std::cout << "Unknown Force Field Type\n\n";
	   exit(EXIT_FAILURE);
	 }
      }
      static const std::string FF_CHARMM, FF_EXOTIC, FF_MARTINI;
   };

   //Files for input.
   struct InFiles
   {
      FileName param; 
      FileNames<BOX_TOTAL> pdb, psf;
      FileName seed;
   };

   //Input section of config file data.
   struct Input
   { 
      RestartSettings restart;
      PRNGKind prng;
      FFKind ffKind;
      InFiles files;
   };

   

   /////////////////////////////////////////////////////////////////////////
   // System-specific structures

   struct Temperature : ReadableBase
   {
      double inKelvin;
      void Read(Reader & config) { config.file >> inKelvin; }
   };

   struct PotentialConfig 
   {uint kind; double cutoff; double oneFourScale; uint VDW_KIND;};
   struct VDWPot : public PotentialConfig { bool doTailCorr; };
   typedef PotentialConfig VDWShift;
   struct VDWSwitch : public PotentialConfig { double cuton; };

   //Items that effect the system interactions and/or identity, e.g. Temp.
   struct FFValues : ReadableBase
   {
      uint VDW_KIND;
      double cutoff, rswitch, oneFourScale;
      bool doTailCorr;
      std::string kind;

      void Read(Reader & config) 
      { 	
	config.file >> kind;
	if(str::compare(VDW, kind))
	{
	  config.file >> doTailCorr >> cutoff >> oneFourScale;
	  VDW_KIND = VDW_STD_KIND;
	}
	else if(str::compare(VDW_SHIFT, kind))
	{
	  config.file >> cutoff >> oneFourScale;
	  VDW_KIND = VDW_SHIFT_KIND;
	  doTailCorr = false;
	  std::cout << "REMINDER! Tail correction are not calculated "
		    << "for shifted potentials\n" << std::endl;
	}
	else if(str::compare(VDW_SWITCH, kind))
	{
	  config.file >> rswitch >> cutoff >> oneFourScale;
	  VDW_KIND = VDW_SWITCH_KIND;
	  doTailCorr = false;
	  std::cout << "REMINDER! Tail Correction are not calculated "
		    << "for switched potentials\n" << std::endl;
	}
	else
	{
	  std::cout << "Unknown potential type found in GOMC configuration\n\n";
	  exit(EXIT_FAILURE);
	}
      }
      static const std::string VDW, VDW_SHIFT, VDW_SWITCH;
      static const uint VDW_STD_KIND, VDW_SHIFT_KIND, VDW_SWITCH_KIND;
   };

#if ENSEMBLE == GEMC
   
   //Items that effect the system interactions and/or identity, e.g. Temp.
   struct GEMCKind : ReadableBase
   {
      uint kind;
      double pressure;

      GEMCKind(): kind(mv::GEMC_NVT) {} 

      void Read(Reader & config) 
      { 
	 std::string s;
	 config.file >> s;
	 if (str::compare(str::ToUpper(s), "NVT"))
	    kind = mv::GEMC_NVT;
	 else
	 {
	    kind = mv::GEMC_NPT;
	    config.file >> pressure;
	    pressure *= unit::BAR_TO_K_MOLECULE_PER_A3;
	 }
      }
   }; 
   
#endif

   struct Step : ReadableBase
   {
      ulong total, equil, adjustment;
      void Read(Reader & config)
      { config.file >> total >> equil >> adjustment; }
   };

   //Holds the percentage of each kind of move for this ensemble.
   struct MovePercents : ReadableBase
   {
      double displace, rotate;
#ifdef VARIABLE_VOLUME
      double volume;
#endif
#ifdef VARIABLE_PARTICLE_NUMBER
      double transfer;
#endif
      void Read(Reader & config)
      { 
	 config.file >> displace >> rotate;
#ifdef VARIABLE_VOLUME
	 config.file >> volume;
#endif
#ifdef VARIABLE_PARTICLE_NUMBER
	 config.file >> transfer;
#endif
      }
   };

   struct Volume : ReadableBase
   {
      bool hasVolume;
      uint boxCoordRead;
      XYZArray axis;
      Volume(void) : hasVolume(false), boxCoordRead(0), axis(BOX_TOTAL)  {}
      void Read(Reader & config) 
      {
	 uint b = 0;
	 config.file >> b;
	 if (b < BOX_TOTAL)
	 {
	    XYZ temp;
	    boxCoordRead++;
	    hasVolume = (boxCoordRead == BOX_TOTAL);
	    config.file >> temp.x >> temp.y >> temp.z;
	    axis.Set(b, temp);  
	 }
      }
   };

   //If particle number varies (e.g. GCMC, GEMC) load in parameters for
   //configurational bias
   struct GrowNonbond : ReadableBase
   {
     uint first, nth;
      void Read(Reader & config)
      { config.file >> first >> nth; }
   };

   //If particle number varies (e.g. GCMC, GEMC) load in parameters for
   //configurational bias
   struct GrowBond : ReadableBase
   {
     uint ang, dih;
      void Read(Reader & config)
      { 
         config.file >> ang >> dih;
      }
   };

   struct CBMC { GrowNonbond nonbonded; GrowBond bonded; };   

#if ENSEMBLE == GCMC
   struct ChemicalPotential : ReadableBase
   {
      std::map<std::string, double> cp;
      void Read(Reader & config)
      {
	 std::string line, resName;
         double val;
	 std::getline(config.file, line);
	 std::stringstream ss(line);
	 while ( ss >> resName >> val )
	    cp[resName] = val;
      }
   };
#endif

   struct SystemVals
   {
      Temperature T;
      FFValues ff;
      Step step;
      MovePercents moves;
      Volume volume; //May go unused
      CBMC cbmcTrials;
#if ENSEMBLE == GCMC
      ChemicalPotential chemPot;
#elif ENSEMBLE == GEMC
      GEMCKind gemc;
#endif
   };

   /////////////////////////////////////////////////////////////////////////
   // Output-specific structures

   struct EventSettings : ReadableStepDependentBase
   {
      bool enable; ulong frequency;
      bool operator()(void) { return enable; }
      void Read(Reader & config, const ulong totalSteps,
		std::string const& kindName)
      { 
	 config.file >> enable >> frequency; 
	 if ( frequency > totalSteps && enable )
	 {
	    std::cerr << "WARNING: Total steps to run is less than "
		      << "the frequency period for " << kindName 
		      << " dumping, values will not be saved."
		      << std::endl << std::endl;
	    enable = false;
	 }
      }
   };



   struct UniqueStr : ReadableBase
   {
      std::string val;
      void Read(Reader & config)
      { config.file >> val; }
   };

   struct HistFiles : ReadableBase
   {
      std::string histName, number, letter, sampleName;
      uint stepsPerHistSample;
      void Read(Reader & config)
      {
         config.file >> histName >> sampleName >> number >> letter
                     >> stepsPerHistSample;
      }
   };

   //Files for output.
   struct OutFiles
   {
      FileNames<BOX_TOTAL> pdb;
      FileName psf, seed;
      HistFiles hist;
   };
   struct Settings { EventSettings block, hist, fluct; UniqueStr uniqueStr; };
	    
   //Enables for each variable that can be tracked
   struct OutputEnables : ReadableBase
   {
      bool block, fluct, hist;
      void Read(Reader & config)
      { config.file >> block >> fluct >> hist; }
   };
	 
   struct TrackedVars
   { 
      OutputEnables energy, pressure;
#ifdef VARIABLE_VOLUME
      OutputEnables volume;
#endif
#ifdef VARIABLE_PARTICLE_NUMBER
      OutputEnables molNum, acceptAngles;
#endif
#ifdef VARIABLE_DENSITY
      OutputEnables density;
#endif
   };

   struct SysState { EventSettings settings; OutFiles files; };
   struct Statistics{ Settings settings; TrackedVars vars; };
   struct Output
   { SysState state, restart; Statistics statistics; EventSettings console; };

}

class ConfigSetup
{
 public:

   config_setup::Input in;
   config_setup::Output out;
   config_setup::SystemVals sys; 
   
   ConfigSetup(void): readVar(SetReadFunctions()), 
      readStepDependVar(SetStepDependentReadFunctions()) {}
   void Init(char const*const fileName);

 private:
   //Polymorphic read function calling.
   const std::map<std::string, ReadableBase *> readVar; 
   const std::map<std::string, ReadableStepDependentBase *> 
      readStepDependVar;
   //Map variable names to functions   
   std::map<std::string, ReadableBase *>  SetReadFunctions(void);
   std::map<std::string, ReadableStepDependentBase *> 
      SetStepDependentReadFunctions(void);

   //Names of config file.
   static const char defaultConfigFileName[]; // "in.dat"
   static const char configFileAlias[];       // "GO-MC Configuration File"	
};

#endif 
