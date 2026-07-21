package com.pawket.shared.time;

import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;

public final class ClockProducer {
    @Produces
    @Singleton
    Clock clock() {
        return Clock.systemUTC();
    }
}
