package com.pawket.memberships.domain.model;

public enum MembershipRole {
    OWNER,
    CARETAKER,
    FOLLOWER;

    public boolean canEditPet() {
        return this == OWNER || this == CARETAKER;
    }
}
