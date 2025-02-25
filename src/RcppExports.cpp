// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

// basinCpp
IntegerMatrix basinCpp(NumericMatrix& dm2, IntegerMatrix& bsn, IntegerMatrix& dun);
RcppExport SEXP _mesoclim_basinCpp(SEXP dm2SEXP, SEXP bsnSEXP, SEXP dunSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericMatrix& >::type dm2(dm2SEXP);
    Rcpp::traits::input_parameter< IntegerMatrix& >::type bsn(bsnSEXP);
    Rcpp::traits::input_parameter< IntegerMatrix& >::type dun(dunSEXP);
    rcpp_result_gen = Rcpp::wrap(basinCpp(dm2, bsn, dun));
    return rcpp_result_gen;
END_RCPP
}
// renumberbasin
IntegerVector renumberbasin(IntegerVector& m, IntegerVector u);
RcppExport SEXP _mesoclim_renumberbasin(SEXP mSEXP, SEXP uSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< IntegerVector& >::type m(mSEXP);
    Rcpp::traits::input_parameter< IntegerVector >::type u(uSEXP);
    rcpp_result_gen = Rcpp::wrap(renumberbasin(m, u));
    return rcpp_result_gen;
END_RCPP
}
// invls_calc
NumericMatrix invls_calc(NumericMatrix lsm, double resolution, double xmin, double ymax, NumericVector s, int direction, NumericMatrix slr, double slr_xmin, double slr_xmax, double slr_ymin, double slr_ymax);
RcppExport SEXP _mesoclim_invls_calc(SEXP lsmSEXP, SEXP resolutionSEXP, SEXP xminSEXP, SEXP ymaxSEXP, SEXP sSEXP, SEXP directionSEXP, SEXP slrSEXP, SEXP slr_xminSEXP, SEXP slr_xmaxSEXP, SEXP slr_yminSEXP, SEXP slr_ymaxSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericMatrix >::type lsm(lsmSEXP);
    Rcpp::traits::input_parameter< double >::type resolution(resolutionSEXP);
    Rcpp::traits::input_parameter< double >::type xmin(xminSEXP);
    Rcpp::traits::input_parameter< double >::type ymax(ymaxSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type s(sSEXP);
    Rcpp::traits::input_parameter< int >::type direction(directionSEXP);
    Rcpp::traits::input_parameter< NumericMatrix >::type slr(slrSEXP);
    Rcpp::traits::input_parameter< double >::type slr_xmin(slr_xminSEXP);
    Rcpp::traits::input_parameter< double >::type slr_xmax(slr_xmaxSEXP);
    Rcpp::traits::input_parameter< double >::type slr_ymin(slr_yminSEXP);
    Rcpp::traits::input_parameter< double >::type slr_ymax(slr_ymaxSEXP);
    rcpp_result_gen = Rcpp::wrap(invls_calc(lsm, resolution, xmin, ymax, s, direction, slr, slr_xmin, slr_xmax, slr_ymin, slr_ymax));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_mesoclim_basinCpp", (DL_FUNC) &_mesoclim_basinCpp, 3},
    {"_mesoclim_renumberbasin", (DL_FUNC) &_mesoclim_renumberbasin, 2},
    {"_mesoclim_invls_calc", (DL_FUNC) &_mesoclim_invls_calc, 11},
    {NULL, NULL, 0}
};

RcppExport void R_init_mesoclim(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
