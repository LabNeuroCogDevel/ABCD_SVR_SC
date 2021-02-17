# ABCD SVM
R and slurm job control scripts for running SVM on a large dataset

## 20210217WF: bridges -> bridges2
update to bridges 2. `pylon5` will move to `/ocean/project/`
Home folder will be lost (?)

### R pacakges
~/Rpackages is compessed into r_3.5pkg.tar.xz

### pylon5 symlinks

```
data   -> /pylon5/ibz3a7p/bct16/data
oldata -> /pylon5/ib5phip/bct16/data/  # GAMM. no home on ocean
```

### home folder scripts

```
tree -dxL 2 ~

├── ABCD_MP_SVR                             # this repo. older copy?
├── data -> /pylon5/ibz3a7p/bct16/data
├── oldata -> /pylon5/ib5phip/bct16/data/
├── Rpackages                               # zipped up and included in repo
│   └── 3.5
└── scripts
    ├── ABCD_CU_SVR                         # moved into this repo
    └── ABCD_MP_SVR                         # this repo. newer copy
```

#### ~/ABCD_MP_SVR

`ABCD_MP_SVR` exists in two places. Inside `~/scripts` was uptodate, inside `~` was behind.

```
$ ls ~/ABCD_MP_SVR
00_sub_svr.sh  ABCD_CU_SVR     oldsc_0x_svrfuncs.R  show_jobs.sh       test.rm
0x_svrfuncs.R  compute_svr.sh  r_3.5pkg.tar.xz      SVRbysamplesize.R
```
