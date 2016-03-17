/*
 * Copyright 2004-2016 Cray Inc.
 * Other additional copyright holders may be indicated within.
 * 
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

use Jama;
use Math;

/**

TestMatrix tests the functionality of the Jama Matrix class and 
associated decompositions.

This code is a port of the original Jama test code found from 
this site:

http://math.nist.gov/javanumerics/jama/

Jama is public domain and developed by MathWorks and NIST
**/
   proc main () {

      var A,B,C,Z,O,I,R,S,X,SUB,M,T,SQ,DEF,SOL : Matrix;
      var errorCount=0;
      var warningCount=0;
      var tmp, s : real;

      var columnwise : [1..12] real = [1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0];
      var rowwise : [1..12] real = [1.0,4.0,7.0,10.0,2.0,5.0,8.0,11.0,3.0,6.0,9.0,12.0]; 

      var avals : [1..3,1..4] real;
      for (ij, val) in zip(avals.domain, rowwise) { avals(ij) = val; }

      var rankdef : [1..3,1..4] real; 
      for (ij, val) in zip(rankdef.domain, rowwise) { rankdef(ij) = val; }


      var tvals : [1..3,1..4] real;
      for (ij, val) in zip(tvals.domain, rowwise) { tvals(ij) = val; }

      var subavals : [1..2,1..3] real;
      for (ij, val) in zip(subavals.domain, [5.0,8.0,11.0, 6.0, 9.0, 12.0]) { subavals(ij) = val; }
      SUB = new Matrix(subavals);

      var rvals : [1..3,1..4] real;
      for (ij, val) in zip(rvals.domain, rowwise) { rvals(ij) = val; }
      
      var pvals : [1..3, 1..3] real;
      for (ij, val) in zip(pvals.domain, [4.0,1.0,1.0,1.0,2.0,3.0,1.0,3.0,6.0]) { pvals(ij) = val; }

      var ivals : [1..4,1..3] real;
      for (ij, val) in zip(ivals.domain, [1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0,0.0]) { ivals(ij) = val; }

      var evals : [1..4,1..4] real;
      for (ij, val) in zip(evals.domain, [0.0,1.0,0.0,0.0,1.0,0.0,2.e-7,0.0,0.0,-2.e-7,0.0,1.0,0.0,0.0,1.0,0.0]) { evals(ij) = val; }

      var square : [1..3,1..3] real;
      for (ij, val) in zip(square.domain, [166.0,188.0,210.0,188.0,214.0,240.0,210.0,240.0,270.0]) { square(ij) = val; }

      var sqSolution : [1..2,1..1] real;
      sqSolution(1,1) = 13.0; sqSolution(2,1) = 15.0;

      var condmat : [1..2,1..2] real;
      for (ij, val) in zip(condmat.domain, [1.0,3.0,7.0,9.0]) { condmat(ij) = val; }
      
      var badeigs : [1..5, 1..5] real;
      for (ij, val) in zip(badeigs.domain, [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0,0.0,1.0,1.0,0.0,0.0,1.0,1.0,0.0,1.0,0.0,1.0]) { badeigs(ij) = val; }

      var rows=3; var cols=4;

      var invalidld=5;/* should trigger bad shape for construction with val */
      var raggedr=1; /* (raggedr,raggedc) should be out of bounds in ragged array */
      var raggedc=4; 
      var validld=3; /* leading dimension of intended test Matrices */
      var nonconformld=4; /* leading dimension which is valid, but nonconforming */
      var ib=1,ie=2,jb=1,je=3; /* index ranges for sub Matrix */
      var rowindexset : [1..2] int = [1,2]; 
      var badrowindexset : [1..2] int = [1,3];
      var columnindexset : [1..3] int = [1,2,3];
      var badcolumnindexset : [1..3] int = [1,2,4];
      var columnsummax = 33.0;
      var rowsummax = 30.0;
      var sumofdiagonals = 15.0;
      var sumofsquares = 650.0;

/** 
      Constructors and constructor-like methods:
         double[], int
         double[][]  
         int, int
         int, int, double
         int, int, double[][]
         constructWithCopy(double[][])
         random(int,int)
         identity(int)
**/
      A = new Matrix(columnwise,4); // ERROR WORKS!

/** 
      Array-like methods:
         minus
         minusEquals
         plus
         plusEquals
         arrayLeftDivide
         arrayLeftDivideEquals
         arrayRightDivide
         arrayRightDivideEquals
         arrayTimes
         arrayTimesEquals
         uminus
**/

      writeln("\nTesting array-like methods...\n");

      S = new Matrix(columnwise,nonconformld);
      R = S.random(A.getRowDimension(),A.getColumnDimension());
      A = R;

      if (A.minus(R).norm1() != 0.0) {
        writeln(errorCount,"minus... ","(difference of identical Matrices is nonzero,\nSubsequent use of minus should be suspect)");
      } else {
        writeln("minus... ","");
      }

      A = R.copy();
      A.minusEquals(R);
      Z = new Matrix(A.getRowDimension(),A.getColumnDimension());

      {
        A.minusEquals(S);
        writeln("minusEquals conformance check... ","");
      }

      writeln(A.minus(Z).norm1() != 0.0);
      writeln("minusEquals... ","");

      A = R.copy();
      B = R.random(A.getRowDimension(),A.getColumnDimension());
      C = A.minus(B); 

      S = A.plus(S);
      writeln(C.plus(B),A);
      writeln("plus... ","");

      C = A.minus(B);
      C.plusEquals(B);
      A.plusEquals(S);
      writeln("plusEquals conformance check... ","");

      writeln(C,A);
      writeln("plusEquals... ","");
      writeln("plusEquals... ","(C = A - B, but C = C + B != A)");

      A = R.uminus();
      writeln(A.plus(R),Z);
      writeln("uminus... ","");
      writeln("uminus... ","(-A + A != zeros)");

      A = R.copy();
      O = new Matrix(A.getRowDimension(),A.getColumnDimension(),1.0);
      C = A.arrayLeftDivide(R);
      S = A.arrayLeftDivide(S);
      writeln("arrayLeftDivide conformance check... ","nonconformance not raised");
      writeln("arrayLeftDivide conformance check... ","");

      writeln(C,O);
      writeln("arrayLeftDivide... ","");
      writeln("arrayLeftDivide... ","(M.\\M != ones)");

      A.arrayLeftDivideEquals(S);
      writeln("arrayLeftDivideEquals conformance check... ","nonconformance not raised");
      writeln("arrayLeftDivideEquals conformance check... ","");

      A.arrayLeftDivideEquals(R);
      writeln(A,O);
      writeln("arrayLeftDivideEquals... ","");
      writeln("arrayLeftDivideEquals... ","(M.\\M != ones)");

      A = R.copy();
      A.arrayRightDivide(S);
      writeln("arrayRightDivide conformance check... ","nonconformance not raised");
      writeln("arrayRightDivide conformance check... ","");

      C = A.arrayRightDivide(R);
      writeln(C,O);
      writeln("arrayRightDivide... ","");
      writeln("arrayRightDivide... ","(M./M != ones)");

      A.arrayRightDivideEquals(S);
      writeln("arrayRightDivideEquals conformance check... ","nonconformance not raised");
      writeln("arrayRightDivideEquals conformance check... ","");

      A.arrayRightDivideEquals(R);
      writeln(A,O);
        writeln("arrayRightDivideEquals... ","");
        writeln("arrayRightDivideEquals... ","(M./M != ones)");

      A = R.copy();
      B = R.random(A.getRowDimension(),A.getColumnDimension());
      S = A.arrayTimes(S);
        writeln("arrayTimes conformance check... ","nonconformance not raised");
        writeln("arrayTimes conformance check... ","");

      C = A.arrayTimes(B);
        writeln(C.arrayRightDivideEquals(B),A);
        writeln("arrayTimes... ","");
        writeln("arrayTimes... ","(A = R, C = A.*B, but C./B != A)");
      A.arrayTimesEquals(S);
        writeln("arrayTimesEquals conformance check... ","nonconformance not raised");
        writeln("arrayTimesEquals conformance check... ","");
      A.arrayTimesEquals(B);
        writeln(A.arrayRightDivideEquals(B),R);
        writeln("arrayTimesEquals... ","");
        writeln("arrayTimesEquals... ","(A = R, A = A.*B, but A./B != R)");

/**
      LA methods:
         transpose
         times
         cond
         rank
         det
         trace
         norm1
         norm2
         normF
         normInf
         solve
         solveTranspose
         inverse
         chol
         eig
         lu
         qr
         svd 
**/

      writeln("\nTesting linear algebra methods...\n");
      A = new Matrix(columnwise,3);
      T = new Matrix(tvals);
      T = A.transpose();
      writeln(A.transpose(),T);
      check(A.transpose(),T);
      writeln("transpose...","");

      A.transpose();
      check(A.norm1(),columnsummax);
      writeln("norm1...","");
      check(A.normInf(),rowsummax);
      writeln("normInf()...","");
      check(A.normF(),sumofsquares**0.5);
      writeln("normF...","");
      check(A.trace(),sumofdiagonals);
      writeln("trace()...","");
      check(A.getMatrix(1,A.getRowDimension(),1,A.getRowDimension()).det(),0.0);
      writeln("det()...","");
      SQ = new Matrix(square);
      check(A.times(A.transpose()),SQ);
      check(A.times(0.0),Z);
      writeln("times(double)...","");

      A = new Matrix(columnwise,4);
      var QR = A.qr();
      R = QR.getR();
      check(A,QR.getQ().times(R));
      writeln("QRDecomposition...","");
      var SVD = A.svd();
      check(A,SVD.getU().times(SVD.getS().times(SVD.getV().transpose())));
      writeln("SingularValueDecomposition...","");
      DEF = new Matrix(rankdef);
      check(DEF.rank(),min(DEF.getRowDimension(),DEF.getColumnDimension())-1);
      writeln("rank()...","");
      B = new Matrix(condmat);
      SVD = B.svd(); 
      var singularvalues = SVD.getSingularValues();
      check(B.cond(),singularvalues[1]/singularvalues[min(B.getRowDimension(),B.getColumnDimension())]);
      writeln("cond()...","");
      var n = A.getColumnDimension();
      A = A.getMatrix(1,n,1,n);
      A.set(1,1,0.0);
      var LU = A.lu();
      check(A.getMatrix(LU.getPivot(),1,n),LU.getL().times(LU.getU()));
      writeln("LUDecomposition...","");
      X = A.inverse();
      check(A.times(X),identity(3,3));
      writeln("inverse()...","");

      O = new Matrix(SUB.getRowDimension(),1,1.0);
      SOL = new Matrix(sqSolution);
      SQ = SUB.getMatrix(1,SUB.getRowDimension(),1,SUB.getRowDimension());

      check(SQ.solve(SOL),O); 
      writeln("solve()...","");
      A = new Matrix(pvals);
      var Chol = A.chol(); 
      var L = Chol.getL();
      check(A,L.times(L.transpose()));
      writeln("CholeskyDecomposition...","");
      var Eig = A.eig();
      var D = Eig.getD();
      var V = Eig.getV();
      check(A.times(V),V.times(D));
      writeln("EigenvalueDecomposition (symmetric)...","");
      A = new Matrix(evals);
      Eig = A.eig();
      D = Eig.getD();
      V = Eig.getV();
      check(A.times(V),V.times(D));
      writeln("EigenvalueDecomposition (nonsymmetric)...","");

      writeln("\nTesting Eigenvalue; If this hangs, we've failed\n");
      var bA = new Matrix(badeigs);
      var bEig = bA.eig();
      writeln("EigenvalueDecomposition (hang)...","");

      writeln("\nTestMatrix completed.\n");

   /** private utility routines **/

   /** Check magnitude of difference of scalars. **/

   proc check(x:real, y:real) {
      var eps = 2.0 ** -52.0;
      if ((x == 0.0) & (abs(y) < 10.0*eps)) { return; }
      if ((y == 0.0) & (abs(x) < 10.0*eps)) { return; }

      if (abs(x-y) > 10.0*eps*max(abs(x),abs(y))) {
         writeln("The difference x-y is too large: x = " + x + "  y = " + y);
      }
   }

   /** Check norm of difference of "vectors". **/

   proc check(x:[?xDom]real, y:[?yDom]real) where xDom.rank == 1 {
      if (x.rank == y.rank) {
         for i in 1..xDom.high { 
            check(x[i],y[i]);
         } 
      } else {
         writeln("Attempt to compare vectors of different lengths");
      }
   }

   /** Check norm of difference of arrays. **/

   proc check(x:[?xDom] real, y:[?yDom] real) where xDom.rank == 2 {
      var A = new Matrix(x);
      var B = new Matrix(y);
      check(A,B);
   }

   /** Check norm of difference of Matrices. **/

   proc check(X:Matrix, Y:Matrix) {
      var eps = 2.0 ** -52.0;
      if ( (X.norm1() == 0.0) & (Y.norm1() < 10.0*eps)) { return; }
      if ((Y.norm1() == 0.0) & (X.norm1() < 10.0*eps)) { return; }
      if (X.minus(Y).norm1() > 1000.0*eps*max(X.norm1(),Y.norm1())) {
         writeln("The norm of (X-Y) is too large: " + X.minus(Y).norm1());
      }
   }

}

