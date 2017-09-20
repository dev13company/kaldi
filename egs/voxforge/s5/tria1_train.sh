#!/bin/bash

# Copyright 2012 Vassil Panayotov
# Apache 2.0

# NOTE: You will want to download the data set first, before executing this script.
#       This can be done for example by:
#       1. Setting the variable DATA_ROOT in path.sh to point to a
#          directory with enough free space (at least 20-25GB
#          currently (Feb 2014))
#       2. Running "getdata.sh"

# The second part of this script comes mostly from egs/rm/s5/run.sh
# with some parameters changed

. ./path.sh || exit 1

# If you have cluster of machines running GridEngine you may want to
# change the train and decode commands in the file below
. ./cmd.sh || exit 1

# The number of parallel jobs to be started for some parts of the recipe
# Make sure you have enough resources(CPUs and RAM) to accomodate this number of jobs
njobs=10

# This recipe can select subsets of VoxForge's data based on the "Pronunciation dialect"
# field in VF's etc/README files. To select all dialects, set this to "English"
dialects="(Indian)"

# The number of randomly selected speakers to be put in the test set
nspk_test=20

# Test-time language model order
lm_order=2

# Word position dependent phones?
pos_dep_phones=true

# The directory below will be used to link to a subset of the user directories
# based on various criteria(currently just speaker's accent)
selected=${DATA_ROOT}/selected

# The user of this script could change some of the above parameters. Example:
# /bin/bash run.sh --pos-dep-phones false
. utils/parse_options.sh || exit 1

[[ $# -ge 1 ]] && { echo "Unexpected arguments"; exit 1; } 

# Select a subset of the data to use
# WARNING: the destination directory will be deleted if it already exists!
#local/voxforge_select.sh --dialect $dialects \
#  ${DATA_ROOT}/extracted ${selected} || exit 1

# Mapping the anonymous speakers to unique IDs
#local/voxforge_map_anonymous.sh ${selected} || exit 1

# Initial normalization of the data
#local/voxforge_data_prep.sh --nspk_test ${nspk_test} ${selected} || exit 1

#local/voxforge_prepare_lm.sh --order ${lm_order} || exit 1

#local/voxforge_prepare_dict.sh || exit 1

#utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
#  data/local/dict '!SIL' data/local/lang data/lang || exit 1

#local/voxforge_format_data.sh || exit 1

mfccdir=${DATA_ROOT}/mfcc
#for x in train test; do
# steps/make_mfcc.sh --cmd "$train_cmd" --nj $njobs \
#   data/$x exp/make_mfcc/$x $mfccdir || exit 1;
# steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
#done

utils/subset_data_dir.sh data/train 1000 data/train.1k  || exit 1;

# train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \
  2200 12000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

# decode tri1
utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph || exit 1;
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/tri1/graph data/test exp/tri1/decode

#draw-tree data/lang/phones.txt exp/tri1/tree | dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf

# align tri1
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
  --use-graphs true data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

