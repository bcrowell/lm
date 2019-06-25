#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define W 30
#define H 30
  /* ... wires are at logical indices [+-W,0] and [0,+-H] */
#define N ((W+H)*2)
  /* ... factor of 2 is how much outside of circuit to include */

double phi[N*2+1][N*2+1][N*2+1];
double phi2[N*2+1][N*2+1][N*2+1];

#define ALPHA 0.3
  /* ... resistance of one wire; resistance of resistor=1 */

#define N_ITER 100
  /* ... print code assumes a multiple of 10 */

void display() {
  /* print out python code describing the potential in the plane of the circuit */
  int i,j,hd,wd;
  printf("a = [\n");
  hd = H+H/5;
  wd = W+W/5;
  for (j= -hd; j<=hd; j++) {
    printf("[");
    for (i= -wd; i<=wd; i++) {
      printf("%12.10lf",phi[i+N][j+N][0+N]);
      if (i<N) {printf(",");}
    }
    printf("]");
    if (j<N) {printf(",");}
    printf("\n");
  }
  printf("]\n");
}

double charge(int i, int j) {
  return phi[i+N][j+N][N]-(1.0/6.0)*(
     phi[i+N-1][j+N][N]
    +phi[i+N+1][j+N][N]
    +phi[i+N][j+N-1][N]
    +phi[i+N][j+N+1][N]
    +phi[i+N][j+N][N-1]
    +phi[i+N][j+N][N+1]
  );
}

void display_charge() {
  int i,j;
  fprintf(stderr,"battery:\n");
  for (j= -H; j<=H; j+=10) {
    fprintf(stderr,"  %10.8lf\n",charge(-W,j));
  }
  fprintf(stderr,"resistor:\n");
  for (j= -H; j<=H; j+=10) {
    fprintf(stderr,"  %10.8lf\n",charge(W,j));
  }
  fprintf(stderr,"top wire:\n");
  for (i= -W; i<=H; i+=10) {
    fprintf(stderr,"  %10.8lf\n",charge(i,H));
  }
  fprintf(stderr,"bottom wire:\n");
  for (i= -W; i<=H; i+=10) {
    fprintf(stderr,"  %10.8lf\n",charge(i,-H));
  }
}

void main() {
  int i,j,k;
  double alpha = ALPHA;
  double vr,vw;  
  int iter;
  /* initialize phi in empty space to be something semi-reasonable */
  for (i= -N; i<=N; i++) {
    for (j= -N; j<=N; j++) {
      for (k= -N; k<=N; k++) {
        phi[i+N][j+N][k+N] = 0.0;
      }
    }
  }
  /* battery and resistor*/
  vr = 1.0/(1+2*alpha); /* voltage drop across resistor */
  for (j= -H; j<=H; j++) {
    double x;
    x = ((double) j)/(2.0*H); /* goes from -0.5 to 0.5 */ 
    phi[-W+N][j+N][N] = x;
    phi[W+N][j+N][N] = x*vr;
  }
  /* wires */
  vw = alpha/(1+2*alpha); /* voltage drop across one wire */
  for (i= -W; i<=H; i++) {
    double x;
    x = ((double) i)/(2.0*H); /* goes from -0.5 to 0.5 */ 
    phi[i+N][H+N][N] = 0.5-vw*(0.5+x); /* top wire; 0.5+x goes from 0 to 1 */
    phi[i+N][-H+N][N] = -0.5+vw*(0.5+x); /* bottom wire */
  }
  int n_iter = N_ITER;
  /* check evolution potential at certain spot for debugging: */
  int ic=-W+1;
  int jc=H/2;
  for (iter=0; iter<=n_iter; iter++) {
    double max_err = 0.0;
    for (i= -N; i<=N; i++) {
      for (j= -N; j<=N; j++) {
        for (k= -N; k<=N; k++) {
          phi2[i+N][j+N][k+N] = phi[i+N][j+N][k+N]; /* gets overwritten unless on wire */
          if (i== -W && j>= -H && j<= H) {continue;}
          if (i== W && j>= -H && j<= H) {continue;}
          if (j== -H && i>= -W && i<= W) {continue;}
          if (j== H && i>= -W && i<= W) {continue;}
          double err;
          double avg = 0.0;
          int n = 0;
          int ii,jj,kk;
          for (ii= i-1; ii<=i+1; ii++) {
            for (jj= j-1; jj<=j+1; jj++) {
              for (kk= k-1; kk<=k+1; kk++) {
                if (ii<-N || ii>N || jj<-N || jj>N || kk<-N || kk>N) {continue;}
                if (ii==0 && jj==0 && kk==0) {continue;}
                ++n;
                avg = avg+phi[ii+N][jj+N][kk+N];
                /*
                if (i==ic && j==jc && k==0) {fprintf(stderr,"averaging in %lf from %d %d %d\n"
                        ,phi[ii+N][jj+N][kk+N],ii,jj,kk);}
                */
              }
            }
          }
          avg = avg/n;
          err = fabs(phi[i+N][j+N][k+N]-avg);
          if (err>max_err) {max_err = err;}
          phi2[i+N][j+N][k+N] = avg;
        }
      }
    }
    for (i= -N; i<=N; i++) {
      for (j= -N; j<=N; j++) {
        for (k= -N; k<=N; k++) {
          phi[i+N][j+N][k+N] = phi2[i+N][j+N][k+N];
        }
      }
    }
    if (iter%(N_ITER/10)==0) {
      fprintf(stderr,"iter=%d of %d, max_err=%10.8lf\n",iter,n_iter,max_err);
      /*
      for (i= -W; i<=ic+3; i++) {
        fprintf(stderr,"%10.8lf ",phi[i+N][jc+N][0+N]);
      }
      fprintf(stderr,"\n");
      */
      display_charge();
    }
  }
  display();
  exit(0);
}
