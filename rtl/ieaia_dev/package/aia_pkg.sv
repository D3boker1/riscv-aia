package aia_pkg;

    localparam DOMAIN_IN_DIRECT_MODE = 0;
    localparam DOMAIN_IN_MSI_MODE = 1;

///////////////////////////////////////////////////////////////////
// User must edit the APLIC Default Config using this parameters  
///////////////////////////////////////////////////////////////////
    localparam UserNrSources = 256;
    localparam UserNrHarts   = 5;
    localparam UserNrDomains = 2; // do not change: 2024-05-28
    localparam UserMinPrio   = 6;
    localparam UserAplicMode = DOMAIN_IN_MSI_MODE;
///////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////
// User must edit the IMSIC Default Config using this parameters  
///////////////////////////////////////////////////////////////////
    localparam UserXLEN           = 64;
    localparam UserNrSourcesImsic = 256;
    localparam UserNrHartsImsic   = 5;
    localparam UserNrVSIntpFiles  = 1;
///////////////////////////////////////////////////////////////////

endpackage