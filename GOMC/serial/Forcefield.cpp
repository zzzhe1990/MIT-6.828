#include "Forcefield.h" //Header spec.
//Setup partner classes
#include "Setup.h"
#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif
#include <math.h>

const double BOLTZMANN = 0.0019872041;

Forcefield::Forcefield()
{
  particles = NULL;
  angles = NULL;

}

Forcefield::~Forcefield()
{
  if(particles != NULL)
    delete particles;
  if( angles!= NULL)
    delete angles;

}

void Forcefield::Init(const Setup& set)
{
   InitBasicVals(set.config.sys.ff, set.config.in.ffKind,
		set.config.sys.T);
   particles->Init(set.ff.mie, set.ff.nbfix, set.config.sys.ff,
		   set.config.in.ffKind);
   bonds.Init(set.ff.bond);
   angles->Init(set.ff.angle);
   dihedrals.Init(set.ff.dih);
}

void Forcefield::InitBasicVals(config_setup::FFValues const& val,
			       config_setup::FFKind const& ffKind,
			       config_setup::Temperature const& T)
{
   useLRC = val.doTailCorr;
   T_in_K = T.inKelvin; 
   rCut = val.cutoff; 
   rCutSq = rCut * rCut;
   rCutOver2 = rCut / 2.0;
   scl_14 = val.oneFourScale;
   beta = 1/T_in_K;

   vdwKind = val.VDW_KIND;
   if(vdwKind == val.VDW_STD_KIND)
     particles = new FFParticle();
   else if(vdwKind == val.VDW_SHIFT_KIND)
     particles = new FF_SHIFT();
   else if (vdwKind == val.VDW_SWITCH_KIND && ffKind.isMARTINI)
     particles = new FF_SWITCH_MARTINI();
   else
     particles = new FF_SWITCH();

   if(ffKind.isMARTINI)
     angles = new FFAngleMartini();
   else
     angles = new FFAngles();
     
}
