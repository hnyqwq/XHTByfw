/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import { formDbInfoArray } from '../../formsetting/formdbsetting/formdbinfo/Index';

let DB_NAME: string = 'form.db'

/**
 * db table column info.
 */
export class ColumnInfo {
  name: string;
  type: string;
  length?: number;
  nullable?: boolean;
  primary?: boolean;
  autoincrement?: boolean;

  constructor(name: string, type: string, length?: number, nullable?: boolean,
              primary?: boolean, autoincrement?: boolean) {
    this.name = name;
    this.type = type;
    this.primary = primary;
    this.length = length;
    this.nullable = nullable;
    this.autoincrement = autoincrement;
  }
}

function createTableSql(tableName: string, columns: Array<ColumnInfo>): string {
  let sql = `create table if not exists ${tableName}(`;
  for (let column of columns) {
    sql = sql.concat(`${column.name} ${column.type}`);
    sql = sql.concat(`${column.length && column.length > 0 ? `(${column.length})` : ''}`);
    sql = sql.concat(`${column.primary ? ' primary key' : ''}`);
    sql = sql.concat(`${column.autoincrement ? ' autoincrement' : ''}`);
    sql = sql.concat(`${column.nullable ? '' : ' not null'}`);
    sql = sql.concat(', ');
  }
  sql = `${sql.substring(0, sql.length - 2)})`;
  return sql;
}
