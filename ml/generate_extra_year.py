from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


EXPENSE_COLUMNS = [
    "raw_materials",
    "salaries",
    "electricity",
    "water",
    "rent",
    "promotion",
    "operations",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate an additional historical year from existing daily expense data."
    )
    parser.add_argument(
        "--source",
        default="ml/data/daily_coffee_expenses.csv",
        help="Daily expense CSV used as the pattern source and combined output.",
    )
    parser.add_argument(
        "--generated-out",
        default="ml/data/daily_coffee_expenses_2024_generated.csv",
        help="Path to save only the generated historical year.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducible generated data.",
    )
    return parser.parse_args()


def generate_previous_year(df: pd.DataFrame, seed: int) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    rows: list[dict[str, object]] = []

    for _, row in df.iterrows():
        new_date = row["date"] - pd.DateOffset(years=1)
        base_factor = 0.88 + rng.normal(0, 0.035)
        seasonal = 1 + 0.03 * np.sin((new_date.dayofyear / 366) * 2 * np.pi)

        values = {}
        for column in EXPENSE_COLUMNS:
            column_noise = rng.normal(1, 0.045)
            values[column] = max(
                0,
                int(round(row[column] * base_factor * seasonal * column_noise)),
            )

        values["total_expense"] = sum(values[column] for column in EXPENSE_COLUMNS)
        rows.append({"date": new_date.strftime("%Y-%m-%d"), **values})

    return pd.DataFrame(rows)


def main() -> None:
    args = parse_args()
    source_path = Path(args.source)
    generated_out = Path(args.generated_out)

    df = pd.read_csv(source_path, parse_dates=["date"]).sort_values("date")
    if df["date"].dt.year.nunique() != 1:
        raise ValueError("Source dataset must contain exactly one year before generation.")

    generated = generate_previous_year(df.reset_index(drop=True), args.seed)
    combined = pd.concat(
        [generated, df.assign(date=df["date"].dt.strftime("%Y-%m-%d"))],
        ignore_index=True,
    )

    generated_out.parent.mkdir(parents=True, exist_ok=True)
    generated.to_csv(generated_out, index=False)
    combined.to_csv(source_path, index=False)

    print(f"Generated rows: {len(generated)}")
    print(f"Combined rows: {len(combined)}")
    print(f"Saved generated year: {generated_out}")
    print(f"Updated source: {source_path}")


if __name__ == "__main__":
    main()
