function est = mynormest(A, L, U)
%NORMEST1 Estimate of 1-norm of matrix by block 1-norm power method.
%   C = NORMEST1(A) returns an estimate C of norm(A,1), where A is N-by-N.
%   A can be an explicit matrix or a function AFUN such that
%   FEVAL(@AFUN,FLAG,X) for the following values of
%     FLAG       returns
%     'dim'      N
%     'real'     1 if A is real, 0 otherwise
%     'notransp' A*X
%     'transp'   A'*X
%
%   C = NORMEST1(A,T) changes the number of columns in the iteration matrix
%   from the default 2.  Choosing T <= N/4 is recommended, otherwise it should
%   be cheaper to form the norm exactly from the elements of A, as is done
%   when N <= 4 or T == N.  If T < 0 then ABS(T) columns are used and trace
%   information is printed.  If T is given as the empty matrix ([]) then the
%   default T is used.
%
%   C = NORMEST1(A,T,X0) specifies a starting matrix X0 with columns of unit
%   1-norm and by default is random for T > 1.  If X0 is given as the empty
%   matrix ([]) then the default X0 is used.
%
%   C = NORMEST1(AFUN,T,X0,P1,P2,...) passes extra inputs P1,P2,... to
%   FEVAL(@AFUN,FLAG,X,P1,P2,...).
%
%   [C,V] = NORMEST1(A,...) and [C,V,W] = NORMEST1(A,...) also return vectors
%   V and W such that W = A*V and NORM(W,1) = C*NORM(V,1).
%
%   [C,V,W,IT] = NORMEST1(A,...) also returns a vector IT such that
%   IT(1) is the number of iterations,
%   IT(2) is the number of products of N-by-N by N-by-T matrices.
%   On average, IT(2) = 4.
%
%   Note: NORMEST1 calls RAND.  If repeatable results are required then
%   invoke RAND('STATE',J), for some J, before calling this function.
%
%   See also CONDEST.

%   Subfunctions: MYSIGN, UNDUPLI, NORMAPP.

%   Reference: N. J. Higham and F. Tisseur,
%   A block algorithm for matrix 1-norm estimation, with an application
%   to 1-norm pseudospectra.
%   SIAM J. Matrix Anal. Appl., 21(4):1185-1201, 2000.

%   Nicholas J. Higham, 9-8-99
%   Copyright 1984-2004 The MathWorks, Inc.
%   $Revision: 1.8.4.2 $  $Date: 2004/01/24 09:22:14 $

n = max(size(A));
A_is_real = isreal(A);

t = 2; 

if n <= 4
    X = eye(n) ;
    Y = U\(L\X) ; %compute inverse directly.can as well do inv(A).
    est = max(sum(abs(Y)) );
end

X = ones(n,2);
X(:,2) = mysign(2*rand(n,1) - ones(n,1));
X = undupli(X, []);
X = X/n;

ind = zeros(2,1); 
vals = zeros(2,1); 
Zvals = zeros(n,1); 
S = zeros(n,2);
est_old = 0;

for it = 1:5
    Y = U\(L\X) ;
    vals = sum(abs(Y));

    if vals(1) > vals(2)
        est = vals(1);
	maxi = 1 ;
    else
        est = vals(2);
	maxi = 2 ;
    end

    if est > est_old || it == 2
	est_j = ind(maxi) ; 
    end

    if it >= 2 && est <= est_old
       est = est_old;
       break ;
    end
    est_old = est;

    S_old = S;
    S = mysign(Y);
    if A_is_real
        SS = S_old'*S; 
	np = sum(max(abs(SS)) == n);
        % every column of S is parallel to a column of S_old
	if np == t
	   break ;
        end
        % Now check/fix cols of S parallel to cols of S or S_old.
        S = undupli(S, S_old);
    end

    Z = L' \ (U' \ S) ; % solve A'*Z = S ;

    % Faster version of `for i=1:n, Zvals(i) = norm(Z(i,:), inf); end':
    Zvals = max(abs(Z),[],2); %inf norm of each row of Z

    if it >= 2
        if max(Zvals) == Zvals(est_j)
	    break ;
	end
    end

    [temp, m] = sort(Zvals);
    % get a permutation that orders Zvals in decreasing order 
    m = m(n:-1:1);
    imax = 2 ; % Number of new unit vectors; may be reduced below (if it > 1).
    if it == 1 
        ind = m(1:2);
        ind_hist = ind;
    else
        rep = sum(ismember(m(1:2), ind_hist));
        if rep == 2
	    break ;
	end
        j = 1;
        for i = 1:2
            while j <= n && any(ind_hist == m(j)) 
                j = j+1;
            end
            if j > n
	        imax = i-1;
	       	break ;
	    end
            ind(i) = m(j);
            j = j+1;
        end
        ind_hist = [ind_hist; ind(1:imax)];
    end

    X = zeros(n,2);
    for j=1:imax
	X(ind(j),j) = 1; 
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subfunctions.

function S = undupli(S, S_old)
%UNDUPLI   Look for and replace columns of S parallel to other columns of S or
%          to columns of Sold.

[n, t] = size(S);
if t == 1
   return
end

if isempty(S_old) % Looking just at S.
   W = [S(:,1) zeros(n,1)];
   jstart = 2;
   last_col = 1;
else              % Looking at S and S_old.
   W = [S_old zeros(n,1)];
   jstart = 1;
   last_col = 2;
end

for j=jstart:2
    rpt = 0 ;
    while max(abs(S(:,j)' * W(:,1:last_col))) == n
          rpt = rpt + 1;
          S(:,j) = mysign(2*rand(n,1) - ones(n,1));
          if rpt > n/2, break, end
    end
    if j < 2
       last_col = last_col + 1;
       W(:,last_col) = S(:,j);
    end
end


function S = mysign(A)
%MYSIGN      True sign function with MYSIGN(0) = 1.
S = sign(A);
S(find(S==0)) = 1;

