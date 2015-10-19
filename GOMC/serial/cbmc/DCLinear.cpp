#include <cassert>
#include "DCLinear.h"
#include "DCSingle.h"
#include "DCOnSphere.h"
#include "DCLink.h"
#include "DCLinkNoDih.h"

using namespace cbmc;

DCLinear::DCLinear(System& sys, const Forcefield& ff,
   const MoleculeKind& kind, const Setup& set) : 
   data(sys, ff, set)
{
   mol_setup::MolMap::const_iterator it = set.mol.kindMap.find(kind.name);
   assert(it != set.mol.kindMap.end());
   const mol_setup::MolKind setupKind = it->second;
   //assuming the molecule's ends are 0 and Length - 1
   uint size = kind.NumAtoms();

   forward.push_back(new DCSingle(&data, 0));
   backward.push_back(new DCSingle(&data, size - 1));

   if (size < 2) return;
   forward.push_back(new DCOnSphere(&data, setupKind, 1, 0));
   backward.push_back(new DCOnSphere(&data, setupKind, size - 2, size - 1));

   if (size < 3) return;
   forward.push_back(new DCLinkNoDih(&data, setupKind, 2, 1));
   backward.push_back(new DCLinkNoDih(&data, setupKind, size - 3, size - 2));

   for (uint i = 3; i < size; ++i)
   {
      forward.push_back(new DCLink(&data, setupKind, i, i - 1));
      backward.push_back(new DCLink(&data, setupKind, size - i - 1, size - i));
   }
}

DCLinear::~DCLinear()
{
   for(uint i = 0; i < forward.size(); ++i)
   {
      delete forward[i];
      delete backward[i];
   }
}

void DCLinear::Build(TrialMol& oldMol, TrialMol& newMol, uint molIndex)
{
   std::vector<DCComponent*>& comps =
     data.prng.randInt(1) ? forward : backward;
   for(uint i = 0; i < comps.size(); ++i)
   {
      comps[i]->PrepareNew();
      comps[i]->BuildNew(newMol, molIndex);
      if(newMol.GetWeight() == 0.0){
	return;
      }
   }
   for(uint i = 0; i < comps.size(); ++i)
   {
       comps[i]->PrepareOld();
       comps[i]->BuildOld(oldMol, molIndex);
   }
   
}
