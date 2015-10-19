#ifndef DCLINKEDHEDRON_H
#define DCLINKEDHEDRON_H
#include "DCComponent.h"
#include "../CBMC.h"
#include "DCHedron.h"

namespace mol_setup { struct MolKind; }

namespace cbmc
{
   class DCData;   
   class DCLinkedHedron : public DCComponent
   {
    public:
      DCLinkedHedron(DCData* data, const mol_setup::MolKind& kind,
		     uint focus, uint prev);
      void PrepareNew();
      void PrepareOld();
      void BuildOld(TrialMol& oldMol, uint molIndex);
      void BuildNew(TrialMol& newMol, uint molIndex);
      DCComponent* Clone() { return new DCLinkedHedron(*this); };
    private:
      void ChooseTorsion(TrialMol& mol, double prevPhi[]);
      double EvalLJ(TrialMol& mol, uint molIndex, bool const isSourceBox = false);
      DCData* data;
      DCHedron hed;
      uint nPrevBonds;
      uint prevBonded[MAX_BONDS];
      //kind[bonded][previous]
      uint dihKinds[MAX_BONDS][MAX_BONDS];
   };
}
#endif
