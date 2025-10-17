package com.pittacode.badcode

import java.time.DayOfWeek
import kotlin.math.ceil

fun calculate(request: MovieTicketRequest): Double {
    var ticketPrice = 40.0

    if (request.date.dayOfWeek == DayOfWeek.SATURDAY
        || request.date.dayOfWeek == DayOfWeek.SUNDAY
    ) {
        ticketPrice = 50.0
    }

    var reduction = 0
    if (request.date.dayOfWeek == DayOfWeek.TUESDAY
        || request.date.dayOfWeek == DayOfWeek.WEDNESDAY
    ) {
        reduction = 25
    }

    if (request.age < 10) {
        if (request.date.dayOfWeek == DayOfWeek.SATURDAY
            || request.date.dayOfWeek == DayOfWeek.SUNDAY
        ) {
            ticketPrice /= 2
        }

        val finalPriceChildren = ticketPrice * (1 - reduction / 100.0)
        return ceil(ticketPrice)
    }

    val finalPrice = ticketPrice * (1 - reduction / 100.0)
    return ceil(finalPrice)
}


data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


