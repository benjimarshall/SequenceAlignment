#ifndef SCORING_H
#define SCORING_H

#define ALIGN_GAIN (5)
#define MISALIGN_PENALTY (-4)
#define GAP_PENALTY (-2)

int match_constant(char a, char b);

int match_blosum50(char a, char b);

#endif // SCORING_H
