#include "BoxDimensions.h"
#include "MoveConst.h" //For cutoff-related fail condition

void BoxDimensions::Init(config_setup::RestartSettings const& restart,
			 config_setup::Volume const& confVolume, 
			 pdb_setup::Cryst1 const& cryst,
			 double rc, double rcSq)
{ 
   const double TENTH_ANGSTROM = 0.1;
   rCut = rc;
   rCutSq = rcSq;
   minBoxSize = rc * rcSq * 8 + TENTH_ANGSTROM;
   std::cout << "Min. Box Size: " << minBoxSize << std::endl;
   if (restart.enable && cryst.hasVolume)
      axis = cryst.axis;
   else if (confVolume.hasVolume)
      axis = confVolume.axis;
   else
   {
      fprintf(stderr, 
            "Error: Box Volume(s) not specified in PDB or in.dat files.\n");
      exit(EXIT_FAILURE);
   }
   halfAx.Init(BOX_TOTAL);
   axis.CopyRange(halfAx, 0, 0, BOX_TOTAL);
   halfAx.ScaleRange(0, BOX_TOTAL, 0.5);
   //Init volume/inverse volume.
   for (uint b = 0; b < BOX_TOTAL; b++)
   {
      volume[b] = axis.x[b] * axis.y[b] * axis.z[b]; 
      volInv[b] = 1.0 / volume[b];
   }
}

uint BoxDimensions::ShiftVolume
(BoxDimensions & newDim, double & scale, const uint b, const double delta) const
{
   uint rejectState = mv::fail_state::NO_FAIL;
   double newVolume = volume[b] + delta;
   newDim = *this;

   //If move would shrink any box axis to be less than 2 * rcut, then
   //automatically reject to prevent errors.
   if ( newVolume < minBoxSize )
   {
      std::cout << "WARNING!!! box shrunk below 2*rc! Auto-rejecting!" << std::endl;
      rejectState = mv::fail_state::VOL_TRANS_WOULD_SHRINK_BOX_BELOW_CUTOFF;
   }
   else
   {
      newDim.SetVolume(b, newVolume);
      scale = newDim.axis.Get(b).x / axis.Get(b).x;
   }
   return rejectState;
}

uint BoxDimensions::ExchangeVolume
(BoxDimensions & newDim, double * scale, const double transfer) const
{
   uint state = mv::fail_state::NO_FAIL;
   //double vRat = volume[bO]*volInv[bN];
   //double expTr = vRat*exp(transfer);
   double vTot = volume[0] + volume[1];
   newDim = *this;
   //newDim.volume[bO] = expTr * vTot / (1 + expTr);

   newDim.SetVolume(0, volume[0] + transfer);
   newDim.SetVolume(1, vTot - newDim.volume[0]);
   //If move would shrink any box axis to be less than 2 * rcut, then
   //automatically reject to prevent errors.
   for (uint b = 0; b < BOX_TOTAL && state == mv::fail_state::NO_FAIL; b++)
   {
	 scale[b] = newDim.axis.Get(b).x / axis.Get(b).x;
	 if (newDim.volume[b] < minBoxSize)
	 {
	    state = mv::fail_state::VOL_TRANS_WOULD_SHRINK_BOX_BELOW_CUTOFF;
	 }
   }
   return state;
}
