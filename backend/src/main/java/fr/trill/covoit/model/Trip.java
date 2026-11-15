package fr.trill.covoit.model;

import fr.trill.covoit.model.enums.TripStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "trip")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Trip {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "trip_id")
    private Long tripId;

    @Column(name = "departure_address", nullable = false, columnDefinition = "TEXT")
    private String departureAddress;

    @Column(name = "arrival_address", nullable = false, columnDefinition = "TEXT")
    private String arrivalAddress;

    @Column(name = "departure_datetime", nullable = false)
    private Instant departureDatetime;

    @Column(name = "offered_seats", nullable = false)
    private Integer offeredSeats;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TripStatus status;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driver_id", nullable = false)
    private AppUser driver;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;
}
