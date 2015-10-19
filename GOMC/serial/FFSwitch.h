#ifndef FF_SWITCH_H
#define FF_SWITCH_H

#include "EnsemblePreprocessor.h" //For "MIE_INT_ONLY" preprocessor.
#include "FFConst.h" //constants related to particles.
#include "../lib/BasicTypes.h" //for uint
#include "../lib/NumLib.h" //For Cb, Sq
#include "FFParticle.h"


///////////////////////////////////////////////////////////////////////
////////////////////////// LJ Switch Style ////////////////////////////
///////////////////////////////////////////////////////////////////////
// Virial and LJ potential calculation:
// Eij = cn * eps_ij * ( (sig_ij/rij)^n - (sig_ij/rij)^6)
// cn = n/(n-6) * ((n/6)^(6/(n-6)))
//

struct FF_SWITCH : public FFParticle
{
 public:

   virtual void CalcAdd(double& en, double& vir, const double distSq,
                const uint kind1, const uint kind2) const;
   virtual void CalcSub(double& en, double& vir, const double distSq,
                const uint kind1, const uint kind2) const;
   virtual double CalcEn(const double distSq,
                 const uint kind1, const uint kind2) const;
   virtual double CalcVir(const double distSq,
                  const uint kind1, const uint kind2) const;
   //!Returns Ezero, no energy correction
   virtual double EnergyLRC(const uint kind1, const uint kind2) const
   {return 0.0;}
   //!!Returns Ezero, no virial correction
   virtual double VirialLRC(const uint kind1, const uint kind2) const
   {return 0.0;}

 private:
   virtual void Calc(double& en, double& vir, const double distSq, uint index,
#ifdef MIE_INT_ONLY
	     const uint n
#else
	     const double n
#endif
	     ) const;

};

inline void FF_SWITCH::CalcAdd(double& en, double& vir, const double distSq,
				const uint kind1, const uint kind2) const
{
   uint idx = FlatIndex(kind1, kind2);
   Calc(en, vir, distSq, idx, n[idx]);
} 

inline void FF_SWITCH::CalcSub(double& en, double& vir, const double distSq,
				const uint kind1, const uint kind2) const
{
   double tempEn=0, tempVir=0;
   uint idx = FlatIndex(kind1, kind2);
   Calc(tempEn, tempVir, distSq, idx, n[idx]);
   en -= tempEn;
   vir = -1.0 * tempVir;
} 

//mie potential
inline double FF_SWITCH::CalcEn(const double distSq,
                                 const uint kind1, const uint kind2) const
{
   uint index = FlatIndex(kind1, kind2);
   
   double rCutSq_rijSq = rCutSq - distSq;
   double rCutSq_rijSq_Sq = rCutSq_rijSq * rCutSq_rijSq;

   double rRat2 = sigmaSq[index]/distSq;
   double rRat4 = rRat2 * rRat2;
   double attract = rRat4 * rRat2;
#ifdef MIE_INT_ONLY
   uint n_ij = n[index];
   double repulse = num::POW(rRat2, rRat4, attract, n_ij);
#else
   double n_ij = n[index];
   double repulse = pow(sqrt(rRat2), n_ij);
#endif

   double fE = rCutSq_rijSq_Sq * factor2 * (factor1 + 2 * distSq);

   const double factE = ( distSq > rOnSq ? fE : 1.0);

   return (epsilon_cn[index] * (repulse-attract)) * factE;
}

//mie potential
inline double FF_SWITCH::CalcVir(const double distSq,
                                  const uint kind1, const uint kind2) const
{
   uint index = FlatIndex(kind1, kind2);

   double rCutSq_rijSq = rCutSq - distSq;
   double rCutSq_rijSq_Sq = rCutSq_rijSq * rCutSq_rijSq;

   double rNeg2 = 1.0/distSq;
   double rRat2 = rNeg2 * sigmaSq[index];
   double rRat4 = rRat2 * rRat2;
   double attract = rRat4 * rRat2;
#ifdef MIE_INT_ONLY
   uint n_ij = n[index];
   double repulse = num::POW(rRat2, rRat4, attract, n_ij);
#else
   double n_ij = n[index];
   double repulse = pow(sqrt(rRat2), n_ij);
#endif

   double fE = rCutSq_rijSq_Sq * factor2 * (factor1 + 2 * distSq);
   double fW = 12.0 * factor2 * rCutSq_rijSq * (rOnSq - distSq);

   const double factE = ( distSq > rOnSq ? fE : 1.0);
   const double factW = ( distSq > rOnSq ? fW : 0.0);

   double Wij = epsilon_cn_6[index] * (nOver6[index]*repulse-attract)*rNeg2;
   double Eij = epsilon_cn[index] * (repulse-attract);
   
   return (Wij * factE - Eij * factW);
}


//mie potential
inline void FF_SWITCH::Calc(double & en, double & vir, 
			     const double distSq, const uint index,
#ifdef MIE_INT_ONLY
			     const uint n,
#else
			     const double n
#endif
			     ) const
{
   double rCutSq_rijSq = rCutSq - distSq;
   double rCutSq_rijSq_Sq = rCutSq_rijSq * rCutSq_rijSq;

   double rNeg2 = 1.0/distSq;
   double rRat2 = rNeg2 * sigmaSq[index];
   double rRat4 = rRat2 * rRat2;
   double attract = rRat4 * rRat2;
#ifdef MIE_INT_ONLY
   double repulse = num::POW(rRat2, rRat4, attract, n);
#else
   double repulse = pow(sqrt(rRat2), n);
#endif

   double fE = rCutSq_rijSq_Sq * factor2 * (factor1 + 2 * distSq);
   double fW = 12.0 * factor2 * rCutSq_rijSq * (rOnSq - distSq);

   const double factE = ( distSq > rOnSq ? fE : 1.0);
   const double factW = ( distSq > rOnSq ? fW : 0.0);

   double Wij = epsilon_cn_6[index] * (nOver6[index]*repulse-attract)*rNeg2;
   double Eij = epsilon_cn[index] * (repulse-attract);
   
   en += Eij * factE;
   vir = Wij * factE - Eij * factW;  
}

#endif /*FF_SWITCH_H*/
