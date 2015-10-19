#include "HistOutput.h"
#include "PDBConst.h"
#include "OutConst.h"
#include "ConfigSetup.h"

#include <sstream>

void Histogram::Init(pdb_setup::Atoms const& atoms,
                     config_setup::Output const& output)
{
   stepsPerOut = output.statistics.settings.hist.frequency;
   enableOut = output.statistics.settings.hist.enable;
   if (enableOut)
   {      
      total = new uint[var->numKinds];
      //Set each kind's initial count to 0
      for (uint k = 0; k < var->numKinds; ++k)
      {
	 total[k] = 0;
      }
      //Assign arrays for boxes of interest
      for (uint b = 0; b < BOXES_WITH_U_NB; ++b)
      {
         name[b] = new std::string[var->numKinds];
         molCount[b] = new uint *[var->numKinds];
	 outF[b] = new std::ofstream[var->numKinds];
         for (uint k = 0; k < var->numKinds; ++k)
         {
            name[b][k] = GetFName(output.state.files.hist.histName,
                                  output.state.files.hist.number,
                                  output.state.files.hist.letter,
                                  b, k);
         }
      }
      //Figure out total of each kind of molecule in ALL boxes, including
      //reservoirs
      for (uint b = 0; b < BOX_TOTAL; ++b)
      {
         for (uint k = 0; k < var->numKinds; ++k)
         {
            total[k] += var->molLookupRef->NumKindInBox(k,b);
         }
      }
      //Allocate and initialize to zero bin for maximum # of particles
      for (uint b = 0; b < BOXES_WITH_U_NB; ++b)
      {
         for (uint k = 0; k < var->numKinds; ++k)
	 {
            molCount[b][k] = new uint[total[k]];
            for (uint n = 0; n < total[k]; ++n)
            {
               molCount[b][k][n]=0;
            }
         }
      }      
   }
}

Histogram::~Histogram()
{
   if (total != NULL) delete[] total;
   for (uint b = 0; b < BOXES_WITH_U_NB; ++b)
   {
      if (name[b] != NULL) delete[] name[b];
      for (uint k = 0; k < var->numKinds; ++k)
      {
         if (molCount[b][k] != NULL) delete[] molCount[b][k];
      }
      if (molCount[b] != NULL) delete[] molCount[b];
   }
}

void Histogram::Sample(const ulong step)
{
   //Don't output until equilibrated.
   if ((step+1) < stepsTillEquil) return;
   //If equilibrated, add to correct bin for each type in each box.
   for (uint b = 0; b < BOXES_WITH_U_NB; ++b)
   {
      for (uint k = 0; k < var->numKinds; ++k)
      {
         uint count = var->numByKindBox[k+var->numKinds * b];
         ++molCount[b][k][count];
      }
   }
}
 
void Histogram::DoOutput(const ulong step)
{
   //Don't output until equilibrated.
   if ((step+1) < stepsTillEquil) return;
   //Write to histogram file, if equilibrated.
   for (uint b = 0; b < BOXES_WITH_U_NB; ++b)
   {
      for (uint k = 0; k < var->numKinds; ++k)
      {
	 outF[b][k].open(name[b][k].c_str(), std::ofstream::out);  
         if (outF[b][k].is_open())   
            PrintKindHist(b, k);
         else
            std::cerr << "Unable to write to file \"" <<  name[b][k] << "\" " 
                      << "(histogram file)" << std::endl;
	 outF[b][k].close();
      }
   }
}
void Histogram::PrintKindHist(const uint b, const uint k)
{
   for (uint n = 0; n < total[k]; ++n)
   {
      if ( molCount[b][k][n] != 0 )
         outF[b][k] << n << " " << molCount[b][k][n] << std::endl;;
   }
}

std::string Histogram::GetFName(std::string const& histName, 
                                std::string const& histNum,
                                std::string const& histLetter,
                                const uint box, const uint kind)
{
   std::stringstream sstrm;
   std::string strKind, fName = "n", strBox;
   sstrm << (kind+1);
   sstrm >> strKind;
   fName += strKind;
   fName += histName;
   fName += histNum;
   fName += histLetter;
   if ( BOXES_WITH_U_NB > 1 )
   {
      fName += "_box";
      sstrm << box;
      sstrm >> strBox;
      fName += strBox;
   }
   fName += ".dat";
   return fName;
}
