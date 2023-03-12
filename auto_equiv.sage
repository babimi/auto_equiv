# Programs to determine the words that make X^s_1 a cycle, but 
# print only one word in each equivalence class under automorphisms.
# We consider only words s such that #_a^\pm(s) = 2 for all a in A,
# so the length of s must be 2n.

def normalize(w):
    """Normalize w so that the first appearances of the letters are in sorted order,
    and the first appearance of each letter is positive."""
    # permute the letters to sort their first appearances
    perm = []
    for a in w:
        if abs(a) not in perm:
            perm.append(abs(a))
    wp = [sgn(a) * (perm.index(abs(a)) + 1) for a in w]
    # make the first appearance of each letter positive
    for k in range(len(wp)):
        if (wp[k] < 0) and (abs(wp[k]) not in wp[:k]):
            x = wp[k]
            wp = [-a if a in [x, -x] else a for a in wp]
    return tuple(wp)

def raw_words(n):
    """Generate all words, not only the reduced ones."""
    if n == 0:
        yield []
    else:
        for w in raw_words(n-1):
            n_w = [1] + [x + sgn(x) for x in w]
            for k in range(1,2*n):
                yield n_w[:k] + [1] + n_w[k:]
                yield n_w[:k] + [-1] + n_w[k:]

def good_reduced_words(n):
    """Discard words that are not reduced, or are not cyclically reduced,
    or have the same first letter as last letter."""
    for w in raw_words(n):
        if all(w[i] != -w[i + 1] for i in range(len(w) - 1)) and w and (w[0] != w[-1]) and (w[0] != -w[-1]):
            yield w

def inverse_w(w):
    """Return the inverse of w."""
    return [-w[k] for k in range(len(w)-1, -1, -1)]

def cyclic_perms(w):
    """Generate the words that can be obtained by cyclic permutations, and/or
    taking the inverse."""
    rotates = ([normalize(w[k:] + w[:k]) for k in range(len(w))] # cyclic shifts
                    + [normalize(inverse_w(w[k:] + w[:k])) for k in range(len(w))]) # also inverses
    nodups = []
    for x in rotates:
        if x not in nodups:
            nodups.append(x)
    return nodups

def cyclic_normalize(w):
    """Return a representative of the words obtained from w by cyclic permutations and inverse."""
    return min( [normalize(x) for x in cyclic_perms(w)] )
            
def X1(w, n):
    """Construct the graph X^s_1"""
    V = list(range(-n, n + 1))
    E = [[0,w[0]], [-w[-1],0]]
    for i in range(len(w) - 1):
        E.append([-w[i], w[i + 1]])       
    return Graph([V, E], format='vertices_and_edges')

def auto_class(w, n, verbose=False, time_interval=1):
    """Generate all words in the automorphism class of w, but only return one
    representative from each cyclic/inverse equivalence class.
    This can be slow. Setting verbose=True will print progress reports.
    The time_interval parameter specifies the number of seconds between reports."""
    equivs = cyclic_perms(w)
    min_equivs = [min(equivs)]
    count = 0
    if verbose:
        import datetime
        starttime = datetime.datetime.now()
        lasttime = starttime
    subsets = Set(range(1, n+1)).subsets()
    while count < len(min_equivs):
        w0 = min_equivs[count]
        for L in subsets:
            for R in subsets:
                for x0 in range(1, n+1):
                  if (x0 not in L) and (x0 not in R):
                    for eps in [1,-1]:
                        x = eps * x0
                        phiw0 = []
                        for a in w0:
                            if a in [x, -x]:
                                phiw0 += [a]
                            elif abs(a) in L and abs(a) in R:
                                phiw0 += [-x, a, x]
                            elif a in R or -a in L:
                                phiw0 += [a, x]
                            elif -a in R or a in L:
                                phiw0 += [-x, a]
                            else:
                                phiw0 += [a]
                        # phiw = normalize(Fn(phiw0).Tietze())
                        # reduce the word
                        i = 0
                        while i < len(phiw0) - 1:
                            if phiw0[i] != -phiw0[i+1]:
                                i += 1
                            else:
                                phiw0.pop(i)
                                phiw0.pop(i)
                                if i > 0:
                                    i -= 1
                        if (len(phiw0) == len(w0)) and (normalize(phiw0) not in equivs):
                            new = cyclic_perms(phiw0)
                            equivs += new
                            min_equivs.append(min(new))
        count += 1
        if verbose:
            timenow = datetime.datetime.now()
            if (3600 * timenow.hour + 60 * timenow.minute + timenow.second) > (3600 * lasttime.hour + 60 * lasttime.minute + lasttime.second):
                print("    ", count, n, len(min_equivs), len(equivs), datetime.datetime.now() - starttime)
                lasttime = timenow
    return equivs


# The following script finds the words of length 2n in F_n such that X^s_1 is 
# a cycle, for n = 1, 2, 3, 4, 5.  Only one representative is printed from each 
# equivalence class under automorphisms.
# Finishing 1-4 should take less than a second, and
# the case n = 5 is likely to take about a minute.
# The case n = 6 would take a few hours, so n = 7 (untested) would probably take months.

for n in range(1,6):
    reps = []
    equivs = []
    for w in good_reduced_words(n):
        if tuple(w) not in equivs:
            # print(w)
            X = X1(w, n)
            if X.is_cycle():
                # print(f"adding {w}")
                ac = auto_class(w, n)
                rep = min(ac)
                reps.append(rep)
                equivs += ac
                # print(f"added {rep}")
    print(n, reps)

# output:
# 1 []
# 2 [(1, 1, 2, 2), (1, 2, -1, -2)]
# 3 [(1, 1, 2, 2, 3, 3)]
# 4 [(1, 1, 2, 2, 3, 3, 4, 4), (1, 2, -1, -2, 3, 4, -3, -4)]
# 5 [(1, 1, 2, 2, 3, 3, 4, 4, 5, 5)]