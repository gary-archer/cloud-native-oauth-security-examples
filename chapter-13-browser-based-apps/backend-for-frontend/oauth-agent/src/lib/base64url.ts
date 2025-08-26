/*
 * A base64url utility
 */
export class Base64Url {

    public static encode(input: Buffer): string {

        return input.toString('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/g, '');
    }

    public static decode(input: string): Buffer {

        const base64 = input
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        return Buffer.from(base64, 'base64');
    }

    public static decodeToString(input: string): string {
        return Base64Url.decode(input).toString();
    }
}
