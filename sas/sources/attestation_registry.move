module sas::attestation_registry {
    use sui::{
        vec_map::{Self, VecMap},
    };

    /// ======== Errors ========

    const EAttestationNotFound: u64 = 0;

    /// ======== OTW ========
    
    public struct ATTESTATION_REGISTRY has drop {}

    /// ======== Structs ========
     
    public struct Status has copy, store {
        is_revoked: bool,
        timestamp: u64,
    }

    public struct AttestationRegistry has key, store {
        id: UID,
        attestation_cnt: u64,
        attestations: VecMap<address, Status>,
    }

    /// ========== Init Function ==========
    
    fun init(_otw: ATTESTATION_REGISTRY, ctx: &mut TxContext) {
        let attestation_registry = AttestationRegistry {
            id: object::new(ctx),
            attestation_cnt: 0,
            attestations: vec_map::empty(),
        };

        transfer::share_object(attestation_registry);
    }

    /// ========== Public-Mutating Functions ==========
    public fun registry(
        self: &mut AttestationRegistry,
        attestation: address
    ) {
        assert!(!self.is_exist(attestation), EAttestationNotFound);
        self.attestations.insert(attestation, Status {
            is_revoked: false,
            timestamp: 0,
        });
        self.attestation_cnt = self.attestation_cnt + 1;
    }

    /// ========== Public-View Functions ==========
    public fun is_exist(
        self: &AttestationRegistry,
        attestation: address
    ): bool {
        self.attestations.contains(&attestation)
    }
    
    public fun attestations(
        self: &AttestationRegistry
    ): vector<address> {
        self.attestations.keys()
    }

    public fun status(
        self: &AttestationRegistry,
        attestation: address
    ): Status {
        assert!(self.is_exist(attestation), EAttestationNotFound);
        *self.attestations.get(&attestation)
    }

    public fun is_revoked(
        self: &AttestationRegistry,
        attestation: address
    ): bool {
        assert!(self.is_exist(attestation), EAttestationNotFound);
        let status = self.status(attestation);
        let Status { is_revoked, .. } = status;
        is_revoked
    }

    public fun get_attestations_paginated(
        self: &AttestationRegistry,
        start: u64,
        limit: u64
    ): vector<address> {
        let mut start_index = start;
        let mut result = vector::empty<address>();
        let mut keys = self.attestations.keys();
        let end_index = std::u64::min(start_index + limit, self.attestation_cnt);
        while (start_index < end_index) {
            vector::push_back(&mut result, vector::remove(&mut keys, start_index));
            start_index = start_index + 1;
        };
        result
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ATTESTATION_REGISTRY {}, ctx);
    }

}