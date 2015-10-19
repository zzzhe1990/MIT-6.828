#ifndef MOLECULES_H
#define MOLECULES_H

#include "../lib/BasicTypes.h" //For uint
#include "MolSetup.h"
#include <map>
#include <string>

namespace pdb_setup { class Atoms; }
class FFSetup;
class Forcefield;
class System;

#include "MoleculeKind.h" //For member var.

//Note: This info is static and will never change in current ensembles
struct Molecules
{
   Molecules();
   ~Molecules();

   const MoleculeKind& GetKind(const uint molIndex) const 
   { return kinds[kIndex[molIndex]]; }

   void Init(Setup& setup, Forcefield& forcefield,
	     System& sys);

   //Kind index of each molecule and start in master particle array
   //Plus counts
   uint* start;
   uint* kIndex;
   uint count;
   uint* countByKind;
   char* chain;

   uint NumAtomsByMol(const uint m) const { return start[m+1]-start[m]; }
   uint NumAtoms(const uint mk) const { return kinds[mk].NumAtoms(); }

   int MolStart(const uint molIndex) const
   { return start[molIndex]; }

   int MolEnd(const uint molIndex) const
   { return start[molIndex + 1]; }

   int MolLength(const uint molIndex) const
   { return MolEnd(molIndex) - MolStart(molIndex); }

   void GetRange(uint & _start, uint & stop, uint & len, const uint m) const
   { 
      _start=start[m]; 
      stop = start[m+1]; 
      len = stop-_start; 
   }

   void GetRangeStartStop(uint & _start, uint & stop, const uint m) const
   { _start=start[m]; stop = start[m+1]; }
   void GetRangeStartLength(uint & _start, uint & len, const uint m) const
   { _start=start[m]; len = start[m+1]-_start; }

   MoleculeKind * kinds;
   uint kindsCount;
   double* pairEnCorrections;
   double* pairVirCorrections;

};


#endif /*MOLECULES_H*/
