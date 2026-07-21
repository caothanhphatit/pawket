package com.pawket.shared.auth;

import java.util.UUID;

public interface CurrentActorProvider {
    UUID userId();
}
