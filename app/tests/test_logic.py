def test_sales_total():
    sales = [100, 200, 300]
    assert sum(sales) == 600


def test_average_sales():
    sales = [100, 200, 300]
    assert sum(sales) / len(sales) == 200


def test_sales_count():
    sales = [100, 200, 300]
    assert len(sales) == 3
