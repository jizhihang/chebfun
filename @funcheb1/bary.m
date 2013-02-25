function fx = bary(x, gvals, kind)
%BARY  Barycentric interpolation on a 1st-kind Chebyshev grid.
%   BARY(X, GVALS) evaluates G(X) using the barycentric interpolation formula,
%   where G is the polynomial interpolant on a 1st-kind Chebyshev grid to the
%   values stored in the columns of GVALS. By default the 1st-kind barycentric
%   formula when evaluating within [-1, 1], and the 1st-kind formula for outside
%   the interval or in the complex plane. (See [1] for details).
%
%   If size(GVALS, 2) > 1 then X should be a column vector. If it is not, a
%   warning is displayed and BARY attempts to return values in the form [G_1(X),
%   G_2(X), ...], where size(G_k(X)) = size(X).
%
%   BARY(X, GVALS, KIND) overrides the default behaviour and uses the KIND
%   barycentric formula, where KIND may be either 1 or 2. 
%
%   Example:
%     xcheb = funcheb1.chebpts(14);
%     fx = 1./( 1 + 25*xcheb.^2 );
%     xx = linspace(-1, 1, 1000);
%     [xx, yy] = meshgrid(xx, xx);
%     ff = bary(xx + 1i*yy, fx);
%     h = surf(xx, yy, 0*xx, angle(-ff));
%     set(h, 'edgealpha', 0)
%     view(0,90), shg
%
%   [1] Webb, Trefethen, and Gonnet, "Stability of Barycentric interpolation
%   formulas for extrapolation", SIAM J. Sci. Comput., 2012.
%
% See also FUNCHEB1.CHEBPTS, FUNCHEB1.BARYWTS, FUNCHEB1.FEVAL.

%  Copyright 2013 by The University of Oxford and The Chebfun Developers.
%  See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This method is bascically a wrapper for @funcheb/bary.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse inputs:
n = size(gvals, 1);

% Chebyshev nodes and barycentric weights:
xk = funcheb1.chebpts(n);
vk = funcheb1.barywts(n);

if ( nargin < 3 )
    kind = [];
end

% Call the superclass method.
fx = bary@funcheb(x, gvals, xk, vk, kind);

end