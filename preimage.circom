// Thus, your circuit takes an input of n hashes (public input) and the preimage of the hash and which hash it is (private input).

pragma circom 2.0.0;

include "./node_modules/circomlib/circuits/poseidon.circom";
include "./node_modules/circomlib/circuits/comparators.circom";

template CalculateTotal(n) {
    signal input in[n];
    signal output out;

    signal sums[n];

    sums[0] <== in[0];

    for (var i = 1; i < n; i++) {
        sums[i] <== sums[i-1] + in[i];
    }

    out <== sums[n-1];
}

template QuinSelector(choices) {
    signal input in[choices];
    signal input index;
    signal output out;
    
    // Ensure that index < choices
    component lessThan = LessThan(4);
    lessThan.in[0] <== index;
    lessThan.in[1] <== choices;
    lessThan.out === 1;

    component calcTotal = CalculateTotal(choices);
    component eqs[choices];

    // For each item, check whether its index equals the input index.
    for (var i = 0; i < choices; i ++) {
        eqs[i] = IsEqual();
        eqs[i].in[0] <== i;
        eqs[i].in[1] <== index;

        // eqs[i].out is 1 if the index matches. As such, at most one input to
        // calcTotal is not 0.
        calcTotal.in[i] <== eqs[i].out * in[i];
    }

    // Returns 0 + 0 + 0 + item
    out <== calcTotal.out;
}

template Preimage(n) {  
  signal input hashes[n]; // public
  signal input preimage;  // private
  signal input hashId;    // private
  signal output out;

  component isLessThan = LessThan(252); // why do i see 252 everywhere and not 255?
  isLessThan.in[0] <== hashId;
  isLessThan.in[1] <== n;
  isLessThan.out === 1;

  component poseidon = Poseidon(1);
  poseidon.inputs[0] <== preimage;

  component isEq = IsEqual();
  component quin = QuinSelector(n);
  for(var i=0; i<n; i++){
    quin.in[i] <== hashes[i];
  }
  quin.index <== hashId;
  

  isEq.in[0] <== quin.out;
  isEq.in[1] <== poseidon.out;

  out <== isEq.out;
}

component main {public [hashes]} = Preimage(4);
