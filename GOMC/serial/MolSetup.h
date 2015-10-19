#ifndef MOLSETUP_H
#define MOLSETUP_H

#include "../lib/BasicTypes.h"
#include "EnsemblePreprocessor.h"

#include <string>
#include <vector>
#include <map>

namespace config_setup { class RestartSettings; }
namespace pdb_setup { class Atoms; }
class FFSetup;

namespace mol_setup {
   //!structure to contain an atom's data during initialization
   struct Atom
   {
      //name (within a molecule) and type (for forcefield params)
      std::string name, type;
      double charge, mass;
      //kind index
      uint kind;

      Atom(std::string const& l_name, std::string const& l_type, 
           const double l_charge, const double l_mass) :
           name(l_name), type(l_type), charge(l_charge), mass(l_mass) {}
   };

   struct Dihedral
   {
      //atoms
      uint a0, a1, a2, a3;
      uint kind;
      Dihedral(uint atom0, uint atom1, uint atom2, uint atom3) 
         : a0(atom0), a1(atom1), a2(atom2), a3(atom3) {}
      //some xplor PSF files have duplicate dihedrals, we need to ignore these
      bool operator == (const Dihedral& other) const;
      bool operator != (const Dihedral& other) const;
   };

   struct Angle
   {
      uint a0, a1, a2;
      uint kind;
      Angle(uint atom0, uint atom1, uint atom2) 
         : a0(atom0), a1(atom1), a2(atom2) {}
   };

   struct Bond
   {
      uint a0, a1;
      uint kind;
      Bond(uint atom0, uint atom1)
         : a0(atom0), a1(atom1) {}
   };

   //!Structure to contain a molecule kind's data during initialization
   struct MolKind
   {
      std::vector<Atom> atoms;
      std::vector<Bond> bonds;
      std::vector<Angle> angles;
      std::vector<Dihedral> dihedrals;

      uint kindIndex;

      //Used to search PSF file for geometry, meaningless after that
      uint firstAtomID, firstMolID;
      //true while the molecule is still open for modification during PSF read
      bool incomplete;
      MolKind() : incomplete(true) {}
   };

   //List of dihedrals with atom at one end, atom first
   std::vector<Dihedral> AtomEndDihs(const MolKind& molKind, uint atom);
   //List of dihedrals with atom and partner in middle, atom in a1
   std::vector<Dihedral> DihsOnBond(const MolKind& molKind, uint atom, uint partner);
   //List of angles with atom at one end, atom first
   std::vector<Angle> AtomEndAngles(const MolKind& molKind, uint atom);
   //List of angles with atom in middle
   std::vector<Angle> AtomMidAngles(const MolKind& molKind, uint atom);
   //List of bonds with atom at one end, atom first
   std::vector<Bond> AtomBonds(const MolKind& molKind, uint atom);

   //first element (string) is name of molecule type
   typedef std::map<std::string, MolKind> MolMap;

   //! Reads one or more PSF files into kindMap
   /*!
    *\param kindMap map to add PSF data to
    *\param psfFilename array of strings containing filenames
    *\param numFiles number of files to read
    *\return -1 if failed, 0 if successful
    */
   int ReadCombinePSF(MolMap& kindMap, const std::string* psfFilename,
		      const int numFiles);
#ifndef NDEBUG
   void PrintMolMapVerbose(const MolMap& kindMap);
   void PrintMolMapBrief(const MolMap& kindMap);
#endif
}

//wrapper struct for consistent interface
struct MolSetup 
{
   mol_setup::MolMap kindMap;
   //reads BoxTotal PSFs and merges the data, placing the results in kindMap
   //returns 0 if read is successful, -1 on a failure
   int Init(const config_setup::RestartSettings& restart,
	    const std::string* psfFilename);

   void AssignKinds(const pdb_setup::Atoms& pdbAtoms, const FFSetup& ffData);
};
#endif
