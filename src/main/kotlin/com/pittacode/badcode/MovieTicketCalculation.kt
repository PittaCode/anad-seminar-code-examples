package com.pittacode.badcode

import java.time.DayOfWeek
import kotlin.math.ceil

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    var basePrice = 40.0

    if (request.date.dayOfWeek == DayOfWeek.SATURDAY || request.date.dayOfWeek == DayOfWeek.SUNDAY) {
        basePrice = 50.0
    }

    var reduction = 0
    if (request.date.dayOfWeek == DayOfWeek.TUESDAY || request.date.dayOfWeek == DayOfWeek.WEDNESDAY) {
        reduction = 25
    }

    if (request.age < 10) {
        if (request.date.dayOfWeek == DayOfWeek.SATURDAY || request.date.dayOfWeek == DayOfWeek.SUNDAY) {
            basePrice /= 2
        }

        val finalPriceChildren = basePrice * (1 - reduction / 100.0)
        return ceil(basePrice)
    }

    val finalPrice = basePrice * (1 - reduction / 100.0)
    return ceil(finalPrice)
}

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


