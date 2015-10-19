#ifndef STATIC_VALS_H
#define STATIC_VALS_H

//General includes
#include "../lib/BasicTypes.h" //For uint
#include "EnsemblePreprocessor.h" //For VARIABLE_<QUANTITY> conditional defines

//Initialization variables


//Member variables
#include "Forcefield.h"
#include "SimEventFrequency.h"
#include "BoxDimensions.h"
#include "MoleculeLookup.h"
#include "Molecules.h"

class Setup;
class System;

class StaticVals
{
 public:
   void Init(Setup & set, System& sys);

#if ENSEMBLE == GEMC
   double pressure;
   uint kindOfGEMC;
#endif
   Forcefield forcefield;
   SimEventFrequency simEventFreq;
   //All the static molecule info --  kind, start index
   Molecules mol;

   double movePerc[mv::MOVE_KINDS_TOTAL];
   double totalPerc;

   //Only include these variables if they're static for this ensemble...
#ifndef VARIABLE_VOLUME
   BoxDimensions boxDimensions;
#endif
#ifndef  VARIABLE_PARTICLE_NUMBER   
   MoleculeLookup molLookup;
#endif
   bool IsEquil(const uint step) { return step >= simEventFreq.tillEquil; }
   bool DoAdjust(const uint move) { return move%simEventFreq.perAdjust == 0; }
   double AcceptPercent(const uint tempAccept)
   { return (double)(tempAccept)/(double)(simEventFreq.perAdjust); }

   void InitMovePercents(config_setup::MovePercents const& percent);
};

#endif /*STATIC_VALS_H*/
